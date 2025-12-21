import { useQuery, useMutation, useQueryClient } from 'react-query'
import { 
  Activity, 
  ActivityCreateRequest, 
  ActivityFilters, 
  PaginatedResponse 
} from '@/types'
import { apiGet, apiPost, apiPut, apiDelete } from '@/utils/api'

// Query keys
export const ACTIVITIES_QUERY_KEY = 'activities'

// Custom hooks for activities
export function useActivities(filters?: ActivityFilters, page = 1, pageSize = 20) {
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

  return useQuery<PaginatedResponse<Activity>>(
    [ACTIVITIES_QUERY_KEY, filters, page, pageSize],
    () => apiGet<PaginatedResponse<Activity>>(`/activities?${queryParams}`),
    {
      keepPreviousData: true,
      staleTime: 5 * 60 * 1000, // 5 minutes
    }
  )
}

export function useActivity(id: string) {
  return useQuery<Activity>(
    [ACTIVITIES_QUERY_KEY, id],
    () => apiGet<Activity>(`/activities/${id}`),
    {
      enabled: !!id,
    }
  )
}

export function useCreateActivity() {
  const queryClient = useQueryClient()

  return useMutation<Activity, Error, ActivityCreateRequest>(
    (data) => apiPost<Activity>('/activities', data),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(ACTIVITIES_QUERY_KEY)
      },
    }
  )
}

export function useUpdateActivity() {
  const queryClient = useQueryClient()

  return useMutation<Activity, Error, { id: string; data: Partial<ActivityCreateRequest> }>(
    ({ id, data }) => apiPut<Activity>(`/activities/${id}`, data),
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

  return useMutation<void, Error, string>(
    (id) => apiDelete<void>(`/activities/${id}`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(ACTIVITIES_QUERY_KEY)
      },
    }
  )
}

// Hook for activity suggestions (auto-complete)
export function useActivitySuggestions(query: string) {
  return useQuery<string[]>(
    ['activity-suggestions', query],
    () => apiGet<string[]>(`/activities/suggestions?q=${encodeURIComponent(query)}`),
    {
      enabled: query.length >= 2,
      staleTime: 10 * 60 * 1000, // 10 minutes
    }
  )
}

// Hook for activity tags
export function useActivityTags() {
  return useQuery<string[]>(
    ['activity-tags'],
    () => apiGet<string[]>('/activities/tags'),
    {
      staleTime: 15 * 60 * 1000, // 15 minutes
    }
  )
}