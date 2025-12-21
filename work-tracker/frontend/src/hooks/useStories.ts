import { useQuery, useMutation, useQueryClient } from 'react-query'
import { 
  Story, 
  StoryCreateRequest, 
  StoryFilters, 
  PaginatedResponse 
} from '@/types'
import { apiGet, apiPost, apiPut, apiDelete } from '@/utils/api'

// Query keys
export const STORIES_QUERY_KEY = 'stories'

// Custom hooks for stories
export function useStories(filters?: StoryFilters, page = 1, pageSize = 20) {
  const queryParams = new URLSearchParams({
    page: page.toString(),
    pageSize: pageSize.toString(),
    ...(filters?.status && { status: filters.status }),
    ...(filters?.search && { search: filters.search }),
    ...(filters?.aiEnhanced !== undefined && { aiEnhanced: filters.aiEnhanced.toString() }),
    ...(filters?.tags && { tags: filters.tags.join(',') }),
  })

  return useQuery<PaginatedResponse<Story>>(
    [STORIES_QUERY_KEY, filters, page, pageSize],
    () => apiGet<PaginatedResponse<Story>>(`/stories?${queryParams}`),
    {
      keepPreviousData: true,
      staleTime: 5 * 60 * 1000, // 5 minutes
    }
  )
}

export function useStory(id: string) {
  return useQuery<Story>(
    [STORIES_QUERY_KEY, id],
    () => apiGet<Story>(`/stories/${id}`),
    {
      enabled: !!id,
    }
  )
}

export function useCreateStory() {
  const queryClient = useQueryClient()

  return useMutation<Story, Error, StoryCreateRequest>(
    (data) => apiPost<Story>('/stories', data),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(STORIES_QUERY_KEY)
      },
    }
  )
}

export function useUpdateStory() {
  const queryClient = useQueryClient()

  return useMutation<Story, Error, { id: string; data: Partial<StoryCreateRequest> }>(
    ({ id, data }) => apiPut<Story>(`/stories/${id}`, data),
    {
      onSuccess: (data) => {
        queryClient.invalidateQueries(STORIES_QUERY_KEY)
        queryClient.setQueryData([STORIES_QUERY_KEY, data.id], data)
      },
    }
  )
}

export function useDeleteStory() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>(
    (id) => apiDelete<void>(`/stories/${id}`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(STORIES_QUERY_KEY)
      },
    }
  )
}

// Hook for AI story enhancement
export function useEnhanceStory() {
  const queryClient = useQueryClient()

  return useMutation<Story, Error, string>(
    (id) => apiPost<Story>(`/stories/${id}/enhance`),
    {
      onSuccess: (data) => {
        queryClient.invalidateQueries(STORIES_QUERY_KEY)
        queryClient.setQueryData([STORIES_QUERY_KEY, data.id], data)
      },
    }
  )
}

// Hook for story tags
export function useStoryTags() {
  return useQuery<string[]>(
    ['story-tags'],
    () => apiGet<string[]>('/stories/tags'),
    {
      staleTime: 15 * 60 * 1000, // 15 minutes
    }
  )
}