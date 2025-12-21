import { Activity, Story, Report } from '@/types'
import { offlineService } from '@/services/offlineService'

// Sync event types
export enum SyncEventType {
  ACTIVITY_CREATED = 'activity_created',
  ACTIVITY_UPDATED = 'activity_updated',
  ACTIVITY_DELETED = 'activity_deleted',
  STORY_CREATED = 'story_created',
  STORY_UPDATED = 'story_updated',
  STORY_DELETED = 'story_deleted',
  REPORT_CREATED = 'report_created',
  REPORT_UPDATED = 'report_updated',
  REPORT_DELETED = 'report_deleted',
  SYNC_REQUEST = 'sync_request',
  SYNC_RESPONSE = 'sync_response',
  CONFLICT_DETECTED = 'conflict_detected'
}

export interface SyncEvent {
  type: SyncEventType
  entityId: string
  entityType: 'activity' | 'story' | 'report'
  data?: any
  timestamp: number
  userId: string
  deviceId: string
  version?: number
}

export interface ConflictResolution {
  entityId: string
  entityType: 'activity' | 'story' | 'report'
  resolution: 'local' | 'remote' | 'merge'
  mergedData?: any
}

export interface SyncStatus {
  isConnected: boolean
  lastSync: number
  pendingConflicts: SyncConflict[]
  syncInProgress: boolean
  deviceId: string
}

export interface SyncConflict {
  entityId: string
  entityType: 'activity' | 'story' | 'report'
  localData: any
  remoteData: any
  localTimestamp: number
  remoteTimestamp: number
  conflictType: 'concurrent_edit' | 'delete_edit' | 'version_mismatch'
}

class SyncService {
  private ws: WebSocket | null = null
  private reconnectAttempts = 0
  private maxReconnectAttempts = 5
  private reconnectDelay = 1000
  private deviceId: string
  private userId: string | null = null
  private eventListeners: Map<string, Set<(event: SyncEvent) => void>> = new Map()
  private conflictListeners: Set<(conflict: SyncConflict) => void> = new Set()
  private statusListeners: Set<(status: SyncStatus) => void> = new Set()
  private pendingConflicts: SyncConflict[] = []
  private syncInProgress = false

  constructor() {
    this.deviceId = this.getOrCreateDeviceId()
  }

  // Initialize sync service
  async initialize(userId: string, accessToken: string): Promise<void> {
    this.userId = userId
    await this.connect(accessToken)
  }

  // Connect to WebSocket server
  private async connect(accessToken: string): Promise<void> {
    if (this.ws?.readyState === WebSocket.OPEN) return

    const wsUrl = this.getWebSocketUrl()
    
    try {
      this.ws = new WebSocket(`${wsUrl}?token=${accessToken}&deviceId=${this.deviceId}`)
      
      this.ws.onopen = () => {
        console.log('Sync WebSocket connected')
        this.reconnectAttempts = 0
        this.notifyStatusChange()
        
        // Request initial sync
        this.requestFullSync()
      }

      this.ws.onmessage = (event) => {
        try {
          const syncEvent: SyncEvent = JSON.parse(event.data)
          this.handleSyncEvent(syncEvent)
        } catch (error) {
          console.error('Failed to parse sync event:', error)
        }
      }

      this.ws.onclose = () => {
        console.log('Sync WebSocket disconnected')
        this.notifyStatusChange()
        this.scheduleReconnect(accessToken)
      }

      this.ws.onerror = (error) => {
        console.error('Sync WebSocket error:', error)
      }

    } catch (error) {
      console.error('Failed to connect to sync WebSocket:', error)
      this.scheduleReconnect(accessToken)
    }
  }

  // Handle incoming sync events
  private async handleSyncEvent(event: SyncEvent): Promise<void> {
    // Ignore events from this device
    if (event.deviceId === this.deviceId) return

    try {
      switch (event.type) {
        case SyncEventType.ACTIVITY_CREATED:
        case SyncEventType.ACTIVITY_UPDATED:
          await this.handleActivitySync(event)
          break
        case SyncEventType.ACTIVITY_DELETED:
          await this.handleActivityDelete(event)
          break
        case SyncEventType.STORY_CREATED:
        case SyncEventType.STORY_UPDATED:
          await this.handleStorySync(event)
          break
        case SyncEventType.STORY_DELETED:
          await this.handleStoryDelete(event)
          break
        case SyncEventType.REPORT_CREATED:
        case SyncEventType.REPORT_UPDATED:
          await this.handleReportSync(event)
          break
        case SyncEventType.REPORT_DELETED:
          await this.handleReportDelete(event)
          break
        case SyncEventType.SYNC_RESPONSE:
          await this.handleSyncResponse(event)
          break
        case SyncEventType.CONFLICT_DETECTED:
          await this.handleConflictDetected(event)
          break
      }

      // Notify listeners
      this.notifyEventListeners(event.type, event)
      
    } catch (error) {
      console.error('Failed to handle sync event:', error)
    }
  }

  // Handle activity synchronization
  private async handleActivitySync(event: SyncEvent): Promise<void> {
    const remoteActivity = event.data as Activity
    const cachedActivities = await offlineService.getCachedActivities(this.userId!)
    const localActivity = cachedActivities.find(a => a.id === event.entityId)

    if (localActivity) {
      // Check for conflicts
      const localTimestamp = new Date(localActivity.updatedAt).getTime()
      const remoteTimestamp = event.timestamp

      if (Math.abs(localTimestamp - remoteTimestamp) > 1000) { // 1 second tolerance
        // Potential conflict detected
        const conflict: SyncConflict = {
          entityId: event.entityId,
          entityType: 'activity',
          localData: localActivity,
          remoteData: remoteActivity,
          localTimestamp,
          remoteTimestamp,
          conflictType: 'concurrent_edit'
        }
        
        this.addConflict(conflict)
        return
      }
    }

    // No conflict, update local cache
    await offlineService.cacheActivities([remoteActivity])
  }

  // Handle activity deletion
  private async handleActivityDelete(event: SyncEvent): Promise<void> {
    const cachedActivities = await offlineService.getCachedActivities(this.userId!)
    const localActivity = cachedActivities.find(a => a.id === event.entityId)

    if (localActivity) {
      // Check if local activity was modified after deletion timestamp
      const localTimestamp = new Date(localActivity.updatedAt).getTime()
      
      if (localTimestamp > event.timestamp) {
        // Conflict: local edit after remote deletion
        const conflict: SyncConflict = {
          entityId: event.entityId,
          entityType: 'activity',
          localData: localActivity,
          remoteData: null,
          localTimestamp,
          remoteTimestamp: event.timestamp,
          conflictType: 'delete_edit'
        }
        
        this.addConflict(conflict)
        return
      }
    }

    // Remove from local cache
    // Note: This would need to be implemented in offlineService
    console.log('Activity deleted remotely:', event.entityId)
  }

  // Handle story synchronization
  private async handleStorySync(event: SyncEvent): Promise<void> {
    const remoteStory = event.data as Story
    const cachedStories = await offlineService.getCachedStories(this.userId!)
    const localStory = cachedStories.find(s => s.id === event.entityId)

    if (localStory) {
      const localTimestamp = new Date(localStory.updatedAt).getTime()
      const remoteTimestamp = event.timestamp

      if (Math.abs(localTimestamp - remoteTimestamp) > 1000) {
        const conflict: SyncConflict = {
          entityId: event.entityId,
          entityType: 'story',
          localData: localStory,
          remoteData: remoteStory,
          localTimestamp,
          remoteTimestamp,
          conflictType: 'concurrent_edit'
        }
        
        this.addConflict(conflict)
        return
      }
    }

    await offlineService.cacheStories([remoteStory])
  }

  // Handle story deletion
  private async handleStoryDelete(event: SyncEvent): Promise<void> {
    const cachedStories = await offlineService.getCachedStories(this.userId!)
    const localStory = cachedStories.find(s => s.id === event.entityId)

    if (localStory) {
      const localTimestamp = new Date(localStory.updatedAt).getTime()
      
      if (localTimestamp > event.timestamp) {
        const conflict: SyncConflict = {
          entityId: event.entityId,
          entityType: 'story',
          localData: localStory,
          remoteData: null,
          localTimestamp,
          remoteTimestamp: event.timestamp,
          conflictType: 'delete_edit'
        }
        
        this.addConflict(conflict)
        return
      }
    }

    console.log('Story deleted remotely:', event.entityId)
  }

  // Handle report synchronization
  private async handleReportSync(event: SyncEvent): Promise<void> {
    const remoteReport = event.data as Report
    await offlineService.cacheReports([remoteReport])
  }

  // Handle report deletion
  private async handleReportDelete(event: SyncEvent): Promise<void> {
    console.log('Report deleted remotely:', event.entityId)
  }

  // Handle sync response
  private async handleSyncResponse(event: SyncEvent): Promise<void> {
    const { activities, stories, reports } = event.data

    if (activities?.length > 0) {
      await offlineService.cacheActivities(activities)
    }
    if (stories?.length > 0) {
      await offlineService.cacheStories(stories)
    }
    if (reports?.length > 0) {
      await offlineService.cacheReports(reports)
    }

    this.syncInProgress = false
    this.notifyStatusChange()
  }

  // Handle conflict detection
  private async handleConflictDetected(event: SyncEvent): Promise<void> {
    const conflict = event.data as SyncConflict
    this.addConflict(conflict)
  }

  // Broadcast sync event to other devices
  async broadcastSyncEvent(event: Omit<SyncEvent, 'deviceId' | 'userId'>): Promise<void> {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return

    const fullEvent: SyncEvent = {
      ...event,
      deviceId: this.deviceId,
      userId: this.userId!
    }

    this.ws.send(JSON.stringify(fullEvent))
  }

  // Request full synchronization
  async requestFullSync(): Promise<void> {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return

    this.syncInProgress = true
    this.notifyStatusChange()

    const syncRequest: SyncEvent = {
      type: SyncEventType.SYNC_REQUEST,
      entityId: '',
      entityType: 'activity',
      timestamp: Date.now(),
      userId: this.userId!,
      deviceId: this.deviceId
    }

    this.ws.send(JSON.stringify(syncRequest))
  }

  // Resolve conflict
  async resolveConflict(resolution: ConflictResolution): Promise<void> {
    const conflictIndex = this.pendingConflicts.findIndex(
      c => c.entityId === resolution.entityId && c.entityType === resolution.entityType
    )

    if (conflictIndex === -1) return

    const conflict = this.pendingConflicts[conflictIndex]
    let resolvedData: any

    switch (resolution.resolution) {
      case 'local':
        resolvedData = conflict.localData
        break
      case 'remote':
        resolvedData = conflict.remoteData
        break
      case 'merge':
        resolvedData = resolution.mergedData || this.mergeData(conflict.localData, conflict.remoteData)
        break
    }

    // Update local cache with resolved data
    switch (conflict.entityType) {
      case 'activity':
        if (resolvedData) {
          await offlineService.cacheActivities([resolvedData])
        }
        break
      case 'story':
        if (resolvedData) {
          await offlineService.cacheStories([resolvedData])
        }
        break
      case 'report':
        if (resolvedData) {
          await offlineService.cacheReports([resolvedData])
        }
        break
    }

    // Broadcast resolution to other devices
    await this.broadcastSyncEvent({
      type: conflict.entityType === 'activity' ? SyncEventType.ACTIVITY_UPDATED :
            conflict.entityType === 'story' ? SyncEventType.STORY_UPDATED :
            SyncEventType.REPORT_UPDATED,
      entityId: conflict.entityId,
      entityType: conflict.entityType,
      data: resolvedData,
      timestamp: Date.now()
    })

    // Remove resolved conflict
    this.pendingConflicts.splice(conflictIndex, 1)
    this.notifyStatusChange()
  }

  // Simple merge strategy (can be enhanced)
  private mergeData(localData: any, remoteData: any): any {
    // For now, use the most recent timestamp
    const localTime = new Date(localData.updatedAt || localData.createdAt).getTime()
    const remoteTime = new Date(remoteData.updatedAt || remoteData.createdAt).getTime()
    
    return localTime > remoteTime ? localData : remoteData
  }

  // Add conflict to pending list
  private addConflict(conflict: SyncConflict): void {
    // Check if conflict already exists
    const existingIndex = this.pendingConflicts.findIndex(
      c => c.entityId === conflict.entityId && c.entityType === conflict.entityType
    )

    if (existingIndex >= 0) {
      this.pendingConflicts[existingIndex] = conflict
    } else {
      this.pendingConflicts.push(conflict)
    }

    this.notifyConflictListeners(conflict)
    this.notifyStatusChange()
  }

  // Get current sync status
  getSyncStatus(): SyncStatus {
    return {
      isConnected: this.ws?.readyState === WebSocket.OPEN,
      lastSync: Date.now(), // This should be tracked properly
      pendingConflicts: [...this.pendingConflicts],
      syncInProgress: this.syncInProgress,
      deviceId: this.deviceId
    }
  }

  // Event listener management
  addEventListener(eventType: SyncEventType, listener: (event: SyncEvent) => void): void {
    const eventKey = eventType.toString()
    if (!this.eventListeners.has(eventKey)) {
      this.eventListeners.set(eventKey, new Set())
    }
    this.eventListeners.get(eventKey)!.add(listener)
  }

  removeEventListener(eventType: SyncEventType, listener: (event: SyncEvent) => void): void {
    const eventKey = eventType.toString()
    this.eventListeners.get(eventKey)?.delete(listener)
  }

  addConflictListener(listener: (conflict: SyncConflict) => void): void {
    this.conflictListeners.add(listener)
  }

  removeConflictListener(listener: (conflict: SyncConflict) => void): void {
    this.conflictListeners.delete(listener)
  }

  addStatusListener(listener: (status: SyncStatus) => void): void {
    this.statusListeners.add(listener)
  }

  removeStatusListener(listener: (status: SyncStatus) => void): void {
    this.statusListeners.delete(listener)
  }

  // Notify listeners
  private notifyEventListeners(eventType: SyncEventType, event: SyncEvent): void {
    const listeners = this.eventListeners.get(eventType.toString())
    if (listeners) {
      listeners.forEach(listener => {
        try {
          listener(event)
        } catch (error) {
          console.error('Error in sync event listener:', error)
        }
      })
    }
  }

  private notifyConflictListeners(conflict: SyncConflict): void {
    this.conflictListeners.forEach(listener => {
      try {
        listener(conflict)
      } catch (error) {
        console.error('Error in conflict listener:', error)
      }
    })
  }

  private notifyStatusChange(): void {
    const status = this.getSyncStatus()
    this.statusListeners.forEach(listener => {
      try {
        listener(status)
      } catch (error) {
        console.error('Error in status listener:', error)
      }
    })
  }

  // Utility methods
  private getOrCreateDeviceId(): string {
    let deviceId = localStorage.getItem('deviceId')
    if (!deviceId) {
      deviceId = `device_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
      localStorage.setItem('deviceId', deviceId)
    }
    return deviceId
  }

  private getWebSocketUrl(): string {
    const baseUrl = import.meta.env.VITE_WS_URL || 'ws://localhost:8000'
    return `${baseUrl}/ws/sync`
  }

  private scheduleReconnect(accessToken: string): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('Max reconnection attempts reached')
      return
    }

    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts)
    this.reconnectAttempts++

    setTimeout(() => {
      console.log(`Attempting to reconnect (${this.reconnectAttempts}/${this.maxReconnectAttempts})`)
      this.connect(accessToken)
    }, delay)
  }

  // Cleanup
  disconnect(): void {
    if (this.ws) {
      this.ws.close()
      this.ws = null
    }
    this.eventListeners.clear()
    this.conflictListeners.clear()
    this.statusListeners.clear()
    this.pendingConflicts = []
  }
}

// Export singleton instance
export const syncService = new SyncService()