import { Activity, Story, Report } from '@/types'

// IndexedDB database name and version
const DB_NAME = 'work-tracker-offline'
const DB_VERSION = 1

// Object store names
const STORES = {
  ACTIVITIES: 'activities',
  STORIES: 'stories',
  REPORTS: 'reports',
  SYNC_QUEUE: 'sync_queue',
  METADATA: 'metadata'
} as const

// Sync operation types
export enum SyncOperation {
  CREATE = 'CREATE',
  UPDATE = 'UPDATE',
  DELETE = 'DELETE'
}

export interface SyncQueueItem {
  id: string
  operation: SyncOperation
  entityType: keyof typeof STORES
  entityId: string
  data?: any
  timestamp: number
  retryCount: number
}

export interface OfflineMetadata {
  lastSync: number
  isOnline: boolean
  pendingSyncCount: number
}

class OfflineService {
  private db: IDBDatabase | null = null
  private isInitialized = false
  private syncInProgress = false

  // Initialize IndexedDB
  async initialize(): Promise<void> {
    if (this.isInitialized) return

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION)

      request.onerror = () => {
        console.error('Failed to open IndexedDB:', request.error)
        reject(request.error)
      }

      request.onsuccess = () => {
        this.db = request.result
        this.isInitialized = true
        console.log('OfflineService initialized')
        resolve()
      }

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result

        // Create activities store
        if (!db.objectStoreNames.contains(STORES.ACTIVITIES)) {
          const activitiesStore = db.createObjectStore(STORES.ACTIVITIES, { keyPath: 'id' })
          activitiesStore.createIndex('userId', 'userId', { unique: false })
          activitiesStore.createIndex('date', 'date', { unique: false })
          activitiesStore.createIndex('category', 'category', { unique: false })
        }

        // Create stories store
        if (!db.objectStoreNames.contains(STORES.STORIES)) {
          const storiesStore = db.createObjectStore(STORES.STORIES, { keyPath: 'id' })
          storiesStore.createIndex('userId', 'userId', { unique: false })
          storiesStore.createIndex('status', 'status', { unique: false })
        }

        // Create reports store
        if (!db.objectStoreNames.contains(STORES.REPORTS)) {
          const reportsStore = db.createObjectStore(STORES.REPORTS, { keyPath: 'id' })
          reportsStore.createIndex('userId', 'userId', { unique: false })
          reportsStore.createIndex('reportType', 'reportType', { unique: false })
        }

        // Create sync queue store
        if (!db.objectStoreNames.contains(STORES.SYNC_QUEUE)) {
          const syncStore = db.createObjectStore(STORES.SYNC_QUEUE, { keyPath: 'id' })
          syncStore.createIndex('timestamp', 'timestamp', { unique: false })
          syncStore.createIndex('entityType', 'entityType', { unique: false })
        }

        // Create metadata store
        if (!db.objectStoreNames.contains(STORES.METADATA)) {
          db.createObjectStore(STORES.METADATA, { keyPath: 'key' })
        }
      }
    })
  }

  // Cache activities locally
  async cacheActivities(activities: Activity[]): Promise<void> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.ACTIVITIES], 'readwrite')
    const store = transaction.objectStore(STORES.ACTIVITIES)

    for (const activity of activities) {
      await this.promisifyRequest(store.put({
        ...activity,
        _cached: true,
        _lastModified: Date.now()
      }))
    }

    await this.updateMetadata({ lastSync: Date.now() })
  }

  // Get cached activities
  async getCachedActivities(userId: string): Promise<Activity[]> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.ACTIVITIES], 'readonly')
    const store = transaction.objectStore(STORES.ACTIVITIES)
    const index = store.index('userId')
    
    const request = index.getAll(userId)
    const activities = await this.promisifyRequest(request)
    
    return activities.map(activity => {
      const { _cached, _lastModified, ...cleanActivity } = activity
      return cleanActivity as Activity
    })
  }

  // Cache stories locally
  async cacheStories(stories: Story[]): Promise<void> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.STORIES], 'readwrite')
    const store = transaction.objectStore(STORES.STORIES)

    for (const story of stories) {
      await this.promisifyRequest(store.put({
        ...story,
        _cached: true,
        _lastModified: Date.now()
      }))
    }

    await this.updateMetadata({ lastSync: Date.now() })
  }

  // Get cached stories
  async getCachedStories(userId: string): Promise<Story[]> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.STORIES], 'readonly')
    const store = transaction.objectStore(STORES.STORIES)
    const index = store.index('userId')
    
    const request = index.getAll(userId)
    const stories = await this.promisifyRequest(request)
    
    return stories.map(story => {
      const { _cached, _lastModified, ...cleanStory } = story
      return cleanStory as Story
    })
  }

  // Cache reports locally
  async cacheReports(reports: Report[]): Promise<void> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.REPORTS], 'readwrite')
    const store = transaction.objectStore(STORES.REPORTS)

    for (const report of reports) {
      await this.promisifyRequest(store.put({
        ...report,
        _cached: true,
        _lastModified: Date.now()
      }))
    }

    await this.updateMetadata({ lastSync: Date.now() })
  }

  // Get cached reports
  async getCachedReports(userId: string): Promise<Report[]> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.REPORTS], 'readonly')
    const store = transaction.objectStore(STORES.REPORTS)
    const index = store.index('userId')
    
    const request = index.getAll(userId)
    const reports = await this.promisifyRequest(request)
    
    return reports.map(report => {
      const { _cached, _lastModified, ...cleanReport } = report
      return cleanReport as Report
    })
  }

  // Add operation to sync queue
  async addToSyncQueue(
    operation: SyncOperation,
    entityType: keyof typeof STORES,
    entityId: string,
    data?: any
  ): Promise<void> {
    await this.ensureInitialized()

    const syncItem: SyncQueueItem = {
      id: `${entityType}_${entityId}_${Date.now()}`,
      operation,
      entityType,
      entityId,
      data,
      timestamp: Date.now(),
      retryCount: 0
    }

    const transaction = this.db!.transaction([STORES.SYNC_QUEUE], 'readwrite')
    const store = transaction.objectStore(STORES.SYNC_QUEUE)
    
    await this.promisifyRequest(store.put(syncItem))
    await this.updatePendingSyncCount()
  }

  // Get pending sync operations
  async getPendingSyncOperations(): Promise<SyncQueueItem[]> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.SYNC_QUEUE], 'readonly')
    const store = transaction.objectStore(STORES.SYNC_QUEUE)
    
    const request = store.getAll()
    return await this.promisifyRequest(request)
  }

  // Remove sync operation from queue
  async removeSyncOperation(id: string): Promise<void> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.SYNC_QUEUE], 'readwrite')
    const store = transaction.objectStore(STORES.SYNC_QUEUE)
    
    await this.promisifyRequest(store.delete(id))
    await this.updatePendingSyncCount()
  }

  // Update sync operation retry count
  async updateSyncOperationRetry(id: string): Promise<void> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.SYNC_QUEUE], 'readwrite')
    const store = transaction.objectStore(STORES.SYNC_QUEUE)
    
    const request = store.get(id)
    const syncItem = await this.promisifyRequest(request)
    
    if (syncItem) {
      syncItem.retryCount += 1
      await this.promisifyRequest(store.put(syncItem))
    }
  }

  // Get offline metadata
  async getMetadata(): Promise<OfflineMetadata> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction([STORES.METADATA], 'readonly')
    const store = transaction.objectStore(STORES.METADATA)
    
    const request = store.get('offline_metadata')
    const metadata = await this.promisifyRequest(request)
    
    return metadata?.value || {
      lastSync: 0,
      isOnline: navigator.onLine,
      pendingSyncCount: 0
    }
  }

  // Update offline metadata
  async updateMetadata(updates: Partial<OfflineMetadata>): Promise<void> {
    await this.ensureInitialized()
    
    const currentMetadata = await this.getMetadata()
    const newMetadata = { ...currentMetadata, ...updates }
    
    const transaction = this.db!.transaction([STORES.METADATA], 'readwrite')
    const store = transaction.objectStore(STORES.METADATA)
    
    await this.promisifyRequest(store.put({
      key: 'offline_metadata',
      value: newMetadata
    }))
  }

  // Update pending sync count
  private async updatePendingSyncCount(): Promise<void> {
    const pendingOps = await this.getPendingSyncOperations()
    await this.updateMetadata({ pendingSyncCount: pendingOps.length })
  }

  // Check if we're currently online
  isOnline(): boolean {
    return navigator.onLine
  }

  // Clear all cached data
  async clearCache(): Promise<void> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction(
      [STORES.ACTIVITIES, STORES.STORIES, STORES.REPORTS],
      'readwrite'
    )
    
    await Promise.all([
      this.promisifyRequest(transaction.objectStore(STORES.ACTIVITIES).clear()),
      this.promisifyRequest(transaction.objectStore(STORES.STORIES).clear()),
      this.promisifyRequest(transaction.objectStore(STORES.REPORTS).clear())
    ])
    
    await this.updateMetadata({ lastSync: 0 })
  }

  // Get cache size information
  async getCacheInfo(): Promise<{
    activitiesCount: number
    storiesCount: number
    reportsCount: number
    pendingSyncCount: number
    lastSync: number
  }> {
    await this.ensureInitialized()
    
    const transaction = this.db!.transaction(
      [STORES.ACTIVITIES, STORES.STORIES, STORES.REPORTS, STORES.SYNC_QUEUE],
      'readonly'
    )
    
    const [activities, stories, reports, syncQueue] = await Promise.all([
      this.promisifyRequest(transaction.objectStore(STORES.ACTIVITIES).count()),
      this.promisifyRequest(transaction.objectStore(STORES.STORIES).count()),
      this.promisifyRequest(transaction.objectStore(STORES.REPORTS).count()),
      this.promisifyRequest(transaction.objectStore(STORES.SYNC_QUEUE).count())
    ])
    
    const metadata = await this.getMetadata()
    
    return {
      activitiesCount: activities,
      storiesCount: stories,
      reportsCount: reports,
      pendingSyncCount: syncQueue,
      lastSync: metadata.lastSync
    }
  }

  // Helper methods
  private async ensureInitialized(): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize()
    }
  }

  private promisifyRequest<T>(request: IDBRequest<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })
  }
}

// Export singleton instance
export const offlineService = new OfflineService()