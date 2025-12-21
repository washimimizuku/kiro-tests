import { useState, useEffect, useCallback } from 'react'
import { offlineService, SyncOperation, SyncQueueItem, OfflineMetadata } from '@/services/offlineService'
import { apiGet, apiPost, apiPut, apiDelete } from '@/utils/api'
import { Activity, Story, Report } from '@/types'

export interface OfflineState {
  isOnline: boolean
  isInitialized: boolean
  pendingSyncCount: number
  lastSync: number
  isSyncing: boolean
  cacheInfo: {
    activitiesCount: number
    storiesCount: number
    reportsCount: number
    pendingSyncCount: number
    lastSync: number
  } | null
}

export interface OfflineActions {
  syncData: () => Promise<void>
  clearCache: () => Promise<void>
  getCacheInfo: () => Promise<void>
  addToSyncQueue: (
    operation: SyncOperation,
    entityType: 'activities' | 'stories' | 'reports',
    entityId: string,
    data?: any
  ) => Promise<void>
}

export function useOffline(): [OfflineState, OfflineActions] {
  const [state, setState] = useState<OfflineState>({
    isOnline: navigator.onLine,
    isInitialized: false,
    pendingSyncCount: 0,
    lastSync: 0,
    isSyncing: false,
    cacheInfo: null
  })

  // Initialize offline service
  useEffect(() => {
    const initializeOffline = async () => {
      try {
        await offlineService.initialize()
        const metadata = await offlineService.getMetadata()
        const cacheInfo = await offlineService.getCacheInfo()
        
        setState(prev => ({
          ...prev,
          isInitialized: true,
          pendingSyncCount: metadata.pendingSyncCount,
          lastSync: metadata.lastSync,
          cacheInfo
        }))
      } catch (error) {
        console.error('Failed to initialize offline service:', error)
      }
    }

    initializeOffline()
  }, [])

  // Listen for online/offline events
  useEffect(() => {
    const handleOnline = async () => {
      setState(prev => ({ ...prev, isOnline: true }))
      await offlineService.updateMetadata({ isOnline: true })
      
      // Auto-sync when coming back online
      if (state.pendingSyncCount > 0) {
        await syncData()
      }
    }

    const handleOffline = async () => {
      setState(prev => ({ ...prev, isOnline: false }))
      await offlineService.updateMetadata({ isOnline: false })
    }

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [state.pendingSyncCount])

  // Sync pending operations with server
  const syncData = useCallback(async (): Promise<void> => {
    if (!state.isOnline || state.isSyncing) return

    setState(prev => ({ ...prev, isSyncing: true }))

    try {
      const pendingOps = await offlineService.getPendingSyncOperations()
      console.log(`Syncing ${pendingOps.length} pending operations`)

      for (const op of pendingOps) {
        try {
          await processSyncOperation(op)
          await offlineService.removeSyncOperation(op.id)
        } catch (error) {
          console.error(`Failed to sync operation ${op.id}:`, error)
          
          // Increment retry count, remove if too many retries
          if (op.retryCount >= 3) {
            console.warn(`Removing failed operation after 3 retries: ${op.id}`)
            await offlineService.removeSyncOperation(op.id)
          } else {
            await offlineService.updateSyncOperationRetry(op.id)
          }
        }
      }

      // Update metadata and cache info
      await offlineService.updateMetadata({ lastSync: Date.now() })
      const cacheInfo = await offlineService.getCacheInfo()
      
      setState(prev => ({
        ...prev,
        pendingSyncCount: cacheInfo.pendingSyncCount,
        lastSync: Date.now(),
        cacheInfo
      }))

    } catch (error) {
      console.error('Sync failed:', error)
    } finally {
      setState(prev => ({ ...prev, isSyncing: false }))
    }
  }, [state.isOnline, state.isSyncing])

  // Process individual sync operation
  const processSyncOperation = async (op: SyncQueueItem): Promise<void> => {
    const { operation, entityType, entityId, data } = op

    switch (entityType) {
      case 'activities':
        await processSyncForActivities(operation, entityId, data)
        break
      case 'stories':
        await processSyncForStories(operation, entityId, data)
        break
      case 'reports':
        await processSyncForReports(operation, entityId, data)
        break
      default:
        throw new Error(`Unknown entity type: ${entityType}`)
    }
  }

  // Process activity sync operations
  const processSyncForActivities = async (
    operation: SyncOperation,
    entityId: string,
    data?: any
  ): Promise<void> => {
    switch (operation) {
      case SyncOperation.CREATE:
        await apiPost<Activity>('/activities', data)
        break
      case SyncOperation.UPDATE:
        await apiPut<Activity>(`/activities/${entityId}`, data)
        break
      case SyncOperation.DELETE:
        await apiDelete(`/activities/${entityId}`)
        break
    }
  }

  // Process story sync operations
  const processSyncForStories = async (
    operation: SyncOperation,
    entityId: string,
    data?: any
  ): Promise<void> => {
    switch (operation) {
      case SyncOperation.CREATE:
        await apiPost<Story>('/stories', data)
        break
      case SyncOperation.UPDATE:
        await apiPut<Story>(`/stories/${entityId}`, data)
        break
      case SyncOperation.DELETE:
        await apiDelete(`/stories/${entityId}`)
        break
    }
  }

  // Process report sync operations
  const processSyncForReports = async (
    operation: SyncOperation,
    entityId: string,
    data?: any
  ): Promise<void> => {
    switch (operation) {
      case SyncOperation.CREATE:
        await apiPost<Report>('/reports', data)
        break
      case SyncOperation.UPDATE:
        await apiPut<Report>(`/reports/${entityId}`, data)
        break
      case SyncOperation.DELETE:
        await apiDelete(`/reports/${entityId}`)
        break
    }
  }

  // Clear all cached data
  const clearCache = useCallback(async (): Promise<void> => {
    try {
      await offlineService.clearCache()
      const cacheInfo = await offlineService.getCacheInfo()
      
      setState(prev => ({
        ...prev,
        cacheInfo,
        lastSync: 0
      }))
    } catch (error) {
      console.error('Failed to clear cache:', error)
    }
  }, [])

  // Get current cache information
  const getCacheInfo = useCallback(async (): Promise<void> => {
    try {
      const cacheInfo = await offlineService.getCacheInfo()
      setState(prev => ({ ...prev, cacheInfo }))
    } catch (error) {
      console.error('Failed to get cache info:', error)
    }
  }, [])

  // Add operation to sync queue
  const addToSyncQueue = useCallback(async (
    operation: SyncOperation,
    entityType: 'activities' | 'stories' | 'reports',
    entityId: string,
    data?: any
  ): Promise<void> => {
    try {
      await offlineService.addToSyncQueue(operation, entityType, entityId, data)
      const metadata = await offlineService.getMetadata()
      
      setState(prev => ({
        ...prev,
        pendingSyncCount: metadata.pendingSyncCount
      }))
    } catch (error) {
      console.error('Failed to add to sync queue:', error)
    }
  }, [])

  const actions: OfflineActions = {
    syncData,
    clearCache,
    getCacheInfo,
    addToSyncQueue
  }

  return [state, actions]
}

// Hook for offline-aware data fetching
export function useOfflineData<T>(
  fetchFn: () => Promise<T>,
  cacheKey: string,
  dependencies: any[] = []
) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)
  const [isFromCache, setIsFromCache] = useState(false)
  const [offlineState] = useOffline()

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)
      setError(null)

      try {
        if (offlineState.isOnline) {
          // Try to fetch from network first
          const result = await fetchFn()
          setData(result)
          setIsFromCache(false)
          
          // Cache the result for offline use
          localStorage.setItem(cacheKey, JSON.stringify({
            data: result,
            timestamp: Date.now()
          }))
        } else {
          // Try to get from cache when offline
          const cached = localStorage.getItem(cacheKey)
          if (cached) {
            const { data: cachedData } = JSON.parse(cached)
            setData(cachedData)
            setIsFromCache(true)
          } else {
            throw new Error('No cached data available offline')
          }
        }
      } catch (err) {
        // If network fails, try cache as fallback
        if (offlineState.isOnline) {
          const cached = localStorage.getItem(cacheKey)
          if (cached) {
            const { data: cachedData } = JSON.parse(cached)
            setData(cachedData)
            setIsFromCache(true)
          } else {
            setError(err as Error)
          }
        } else {
          setError(err as Error)
        }
      } finally {
        setLoading(false)
      }
    }

    if (offlineState.isInitialized) {
      fetchData()
    }
  }, [offlineState.isOnline, offlineState.isInitialized, cacheKey, ...dependencies])

  return { data, loading, error, isFromCache }
}