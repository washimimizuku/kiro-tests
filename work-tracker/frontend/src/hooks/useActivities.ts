import { useQuery, useMutation, useQueryClient } from 'react-query'
import { 
  Activity, 
  ActivityCreateRequest, 
  ActivityFilters, 
  PaginatedResponse 
} from '@/types'
import { apiGet, apiPost, apiPut, apiDelete } from '@/utils/api'
import { useOffline, useOfflineData } from '@/hooks/useOffline'
import { useSyncBroadcast } from '@/hooks/useSync'
import { offlineService, SyncOperation } from '@/services/offlineService'
import { useAuth } from '@/contexts/AuthContext'

// Query keys
export const ACTIVITIES_QUERY_KEY = 'activities'

// Custom hooks for activities with offline support
export function useActivities(filters?: ActivityFilters, page = 1, pageSize = 20) {
  const { user } = useAuth()
  const [offlineState, offlineActions] = useOffline()
  
  const queryParams = new URLSearchParams({
    page: page.toString(),
    pageSize: pageSize.toString(),
    ...(filters?.category && { category: filters.category }),
    ...(filters?.search && { search: filters.search }),
    ...(filters?.dateFrom && { dateFrom: filters.dateFrom }),
    ...(filters?.dateTo && { dateTo: filters.dateTo }),
    ...(filters?.impactLevel && { impactLevel: filters.impactLevel.toString() }),
    ...(filters?.tags && { tags: filters.tags.join(',') }),
  })

  // Use offline-aware data fetching
  const { data, loading, error, isFromCache } = useOfflineData<PaginatedResponse<Activity>>(
    () => apiGet<PaginatedResponse<Activity>>(`/activities?${queryParams}`),
    `activities-${JSON.stringify(filters)}-${page}-${pageSize}`,
    [filters, page, pageSize]
  )

  // Also use react-query for online functionality
  const queryResult = useQuery<PaginatedResponse<Activity>>(
    [ACTIVITIES_QUERY_KEY, filters, page, pageSize],
    async () => {
      const result = await apiGet<PaginatedResponse<Activity>>(`/activities?${queryParams}`)
      
      // Cache activities for offline use
      if (user?.id && result.data.length > 0) {
        await offlineService.cacheActivities(result.data)
      }
      
      return result
    },
    {
      enabled: offlineState.isOnline,
      keepPreviousData: true,
      staleTime: 5 * 60 * 1000, // 5 minutes
    }
  )

  // Return offline data when offline, online data when online
  if (!offlineState.isOnline && data) {
    return {
      data,
      isLoading: loading,
      error,
      isFromCache: true,
      refetch: () => Promise.resolve({ data })
    }
  }

  return {
    ...queryResult,
    isFromCache: false
  }
}

export function useActivity(id: string) {
  const [offlineState] = useOffline()
  
  return useQuery<Activity>(
    [ACTIVITIES_QUERY_KEY, id],
    () => apiGet<Activity>(`/activities/${id}`),
    {
      enabled: !!id && offlineState.isOnline,
    }
  )
}

export function useCreateActivity() {
  const queryClient = useQueryClient()
  const { user } = useAuth()
  const [offlineState, offlineActions] = useOffline()
  const { broadcastActivityChange } = useSyncBroadcast()

  return useMutation<Activity, Error, ActivityCreateRequest>(
    async (data) => {
      if (offlineState.isOnline) {
        // Online: create immediately
        const result = await apiPost<Activity>('/activities', data)
        
        // Cache the new activity
        if (user?.id) {
          await offlineService.cacheActivities([result])
        }
        
        // Broadcast to other devices
        await broadcastActivityChange('created', result.id, result)
        
        return result
      } else {
        // Offline: create temporary activity and queue for sync
        const tempActivity: Activity = {
          id: `temp-${Date.now()}`,
          userId: user?.id || '',
          title: data.title,
          description: data.description || '',
          category: data.category,
          tags: data.tags,
          impactLevel: data.impactLevel,
          date: data.date,
          durationMinutes: data.durationMinutes,
          metadata: data.metadata || {},
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        }
        
        // Cache locally
        await offlineService.cacheActivities([tempActivity])
        
        // Add to sync queue
        await offlineActions.addToSyncQueue(
          SyncOperation.CREATE,
          'activities',
          tempActivity.id,
          data
        )
        
        return tempActivity
      }
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(ACTIVITIES_QUERY_KEY)
      },
    }
  )
}

export function useUpdateActivity() {
  const queryClient = useQueryClient()
  const { user } = useAuth()
  const [offlineState, offlineActions] = useOffline()
  const { broadcastActivityChange } = useSyncBroadcast()

  return useMutation<Activity, Error, { id: string; data: Partial<ActivityCreateRequest> }>(
    async ({ id, data }) => {
      if (offlineState.isOnline) {
        // Online: update immediately
        const result = await apiPut<Activity>(`/activities/${id}`, data)
        
        // Update cache
        if (user?.id) {
          await offlineService.cacheActivities([result])
        }
        
        // Broadcast to other devices
        await broadcastActivityChange('updated', result.id, result)
        
        return result
      } else {
        // Offline: update locally and queue for sync
        const cachedActivities = await offlineService.getCachedActivities(user?.id || '')
        const existingActivity = cachedActivities.find(a => a.id === id)
        
        if (existingActivity) {
          const updatedActivity: Activity = {
            ...existingActivity,
            ...data,
            updatedAt: new Date().toISOString()
          }
          
          // Update cache
          await offlineService.cacheActivities([updatedActivity])
          
          // Add to sync queue
          await offlineActions.addToSyncQueue(
            SyncOperation.UPDATE,
            'activities',
            id,
            data
          )
          
          return updatedActivity
        }
        
        throw new Error('Activity not found in cache')
      }
    },
    {
      onSuccess: (data) => {
        queryClient.invalidateQueries(ACTIVITIES_QUERY_KEY)
        queryClient.setQueryData([ACTIVITIES_QUERY_KEY, data.id], data)
      },
    }
  )
}

export function useDeleteActivity() {
  const queryClient = useQueryClient()
  const [offlineState, offlineActions] = useOffline()
  const { broadcastActivityChange } = useSyncBroadcast()

  return useMutation<void, Error, string>(
    async (id) => {
      if (offlineState.isOnline) {
        // Online: delete immediately
        await apiDelete<void>(`/activities/${id}`)
        
        // Broadcast to other devices
        await broadcastActivityChange('deleted', id)
      } else {
        // Offline: queue for sync (don't remove from cache until synced)
        await offlineActions.addToSyncQueue(
          SyncOperation.DELETE,
          'activities',
          id
        )
      }
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries(ACTIVITIES_QUERY_KEY)
      },
    }
  )
}

// Hook for activity suggestions (auto-complete)
export function useActivitySuggestions(query: string) {
  const [offlineState] = useOffline()
  
  return useQuery<string[]>(
    ['activity-suggestions', query],
    () => apiGet<string[]>(`/activities/suggestions?q=${encodeURIComponent(query)}`),
    {
      enabled: query.length >= 2 && offlineState.isOnline,
      staleTime: 10 * 60 * 1000, // 10 minutes
    }
  )
}

// Hook for activity tags
export function useActivityTags() {
  const [offlineState] = useOffline()
  
  return useQuery<string[]>(
    ['activity-tags'],
    () => apiGet<string[]>('/activities/tags'),
    {
      enabled: offlineState.isOnline,
      staleTime: 15 * 60 * 1000, // 15 minutes
    }
  )
}