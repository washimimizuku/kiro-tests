import { useState, useEffect, useCallback } from 'react'
import { syncService, SyncStatus, SyncConflict, ConflictResolution, SyncEventType, SyncEvent } from '@/services/syncService'
import { useAuth } from '@/contexts/AuthContext'

export interface SyncState {
  status: SyncStatus
  isInitialized: boolean
  error: string | null
}

export interface SyncActions {
  initialize: () => Promise<void>
  requestSync: () => Promise<void>
  resolveConflict: (resolution: ConflictResolution) => Promise<void>
  disconnect: () => void
}

export function useSync(): [SyncState, SyncActions] {
  const { user, isAuthenticated } = useAuth()
  const [state, setState] = useState<SyncState>({
    status: {
      isConnected: false,
      lastSync: 0,
      pendingConflicts: [],
      syncInProgress: false,
      deviceId: ''
    },
    isInitialized: false,
    error: null
  })

  // Initialize sync service when user is authenticated
  useEffect(() => {
    if (isAuthenticated && user && !state.isInitialized) {
      initializeSync()
    }
  }, [isAuthenticated, user, state.isInitialized])

  // Set up status listener
  useEffect(() => {
    const handleStatusChange = (status: SyncStatus) => {
      setState(prev => ({ ...prev, status }))
    }

    syncService.addStatusListener(handleStatusChange)

    return () => {
      syncService.removeStatusListener(handleStatusChange)
    }
  }, [])

  // Initialize sync service
  const initializeSync = useCallback(async (): Promise<void> => {
    if (!user) return

    try {
      setState(prev => ({ ...prev, error: null }))
      
      const accessToken = localStorage.getItem('accessToken')
      if (!accessToken) {
        throw new Error('No access token available')
      }

      await syncService.initialize(user.id, accessToken)
      
      setState(prev => ({ 
        ...prev, 
        isInitialized: true,
        status: syncService.getSyncStatus()
      }))
    } catch (error) {
      console.error('Failed to initialize sync service:', error)
      setState(prev => ({ 
        ...prev, 
        error: error instanceof Error ? error.message : 'Failed to initialize sync'
      }))
    }
  }, [user])

  // Request manual sync
  const requestSync = useCallback(async (): Promise<void> => {
    try {
      setState(prev => ({ ...prev, error: null }))
      await syncService.requestFullSync()
    } catch (error) {
      console.error('Failed to request sync:', error)
      setState(prev => ({ 
        ...prev, 
        error: error instanceof Error ? error.message : 'Failed to sync'
      }))
    }
  }, [])

  // Resolve conflict
  const resolveConflict = useCallback(async (resolution: ConflictResolution): Promise<void> => {
    try {
      setState(prev => ({ ...prev, error: null }))
      await syncService.resolveConflict(resolution)
    } catch (error) {
      console.error('Failed to resolve conflict:', error)
      setState(prev => ({ 
        ...prev, 
        error: error instanceof Error ? error.message : 'Failed to resolve conflict'
      }))
    }
  }, [])

  // Disconnect sync service
  const disconnect = useCallback((): void => {
    syncService.disconnect()
    setState(prev => ({ 
      ...prev, 
      isInitialized: false,
      status: {
        isConnected: false,
        lastSync: 0,
        pendingConflicts: [],
        syncInProgress: false,
        deviceId: ''
      }
    }))
  }, [])

  const actions: SyncActions = {
    initialize: initializeSync,
    requestSync,
    resolveConflict,
    disconnect
  }

  return [state, actions]
}

// Hook for listening to specific sync events
export function useSyncEvents(eventTypes: SyncEventType[], handler: (event: SyncEvent) => void) {
  useEffect(() => {
    // Add listeners for each event type
    eventTypes.forEach(eventType => {
      syncService.addEventListener(eventType, handler)
    })

    // Cleanup listeners
    return () => {
      eventTypes.forEach(eventType => {
        syncService.removeEventListener(eventType, handler)
      })
    }
  }, [eventTypes, handler])
}

// Hook for conflict management
export function useConflicts() {
  const [conflicts, setConflicts] = useState<SyncConflict[]>([])

  useEffect(() => {
    const handleConflict = (conflict: SyncConflict) => {
      setConflicts(prev => {
        // Check if conflict already exists
        const existingIndex = prev.findIndex(
          c => c.entityId === conflict.entityId && c.entityType === conflict.entityType
        )

        if (existingIndex >= 0) {
          // Update existing conflict
          const updated = [...prev]
          updated[existingIndex] = conflict
          return updated
        } else {
          // Add new conflict
          return [...prev, conflict]
        }
      })
    }

    const handleStatusChange = (status: SyncStatus) => {
      setConflicts(status.pendingConflicts)
    }

    syncService.addConflictListener(handleConflict)
    syncService.addStatusListener(handleStatusChange)

    // Initialize with current conflicts
    setConflicts(syncService.getSyncStatus().pendingConflicts)

    return () => {
      syncService.removeConflictListener(handleConflict)
      syncService.removeStatusListener(handleStatusChange)
    }
  }, [])

  return conflicts
}

// Hook for broadcasting sync events
export function useSyncBroadcast() {
  const broadcastActivityChange = useCallback(async (
    type: 'created' | 'updated' | 'deleted',
    activityId: string,
    activityData?: any
  ) => {
    const eventType = type === 'created' ? SyncEventType.ACTIVITY_CREATED :
                     type === 'updated' ? SyncEventType.ACTIVITY_UPDATED :
                     SyncEventType.ACTIVITY_DELETED

    await syncService.broadcastSyncEvent({
      type: eventType,
      entityId: activityId,
      entityType: 'activity',
      data: activityData,
      timestamp: Date.now()
    })
  }, [])

  const broadcastStoryChange = useCallback(async (
    type: 'created' | 'updated' | 'deleted',
    storyId: string,
    storyData?: any
  ) => {
    const eventType = type === 'created' ? SyncEventType.STORY_CREATED :
                     type === 'updated' ? SyncEventType.STORY_UPDATED :
                     SyncEventType.STORY_DELETED

    await syncService.broadcastSyncEvent({
      type: eventType,
      entityId: storyId,
      entityType: 'story',
      data: storyData,
      timestamp: Date.now()
    })
  }, [])

  const broadcastReportChange = useCallback(async (
    type: 'created' | 'updated' | 'deleted',
    reportId: string,
    reportData?: any
  ) => {
    const eventType = type === 'created' ? SyncEventType.REPORT_CREATED :
                     type === 'updated' ? SyncEventType.REPORT_UPDATED :
                     SyncEventType.REPORT_DELETED

    await syncService.broadcastSyncEvent({
      type: eventType,
      entityId: reportId,
      entityType: 'report',
      data: reportData,
      timestamp: Date.now()
    })
  }, [])

  return {
    broadcastActivityChange,
    broadcastStoryChange,
    broadcastReportChange
  }
}