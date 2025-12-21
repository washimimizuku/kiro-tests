import { useQuery, useMutation, useQueryClient } from 'react-query'
import { 
  Report, 
  ReportGenerateRequest, 
  PaginatedResponse 
} from '@/types'
import { apiGet, apiPost, apiDelete } from '@/utils/api'

// Query keys
export const REPORTS_QUERY_KEY = 'reports'

// Custom hooks for reports
export function useReports(page = 1, pageSize = 20) {
  const queryParams = new URLSearchParams({
    page: page.toString(),
    pageSize: pageSize.toString(),
  })

  return useQuery<PaginatedResponse<Report>>(
    [REPORTS_QUERY_KEY, page, pageSize],
    () => apiGet<PaginatedResponse<Report>>(`/reports?${queryParams}`),
    {
      keepPreviousData: true,
      staleTime: 5 * 60 * 1000, // 5 minutes
    }
  )
}

export function useReport(id: string) {
  return useQuery<Report>(
    [REPORTS_QUERY_KEY, id],
    () => apiGet<Report>(`/reports/${id}`),
    {
      enabled: !!id,
    }
  )
}

export function useGenerateReport() {
  const queryClient = useQueryClient()

  return useMutation<Report, Error, ReportGenerateRequest>(
    (data) => apiPost<Report>('/reports/generate', data),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(REPORTS_QUERY_KEY)
      },
    }
  )
}

export function useDeleteReport() {
  const queryClient = useQueryClient()

  return useMutation<void, Error, string>(
    (id) => apiDelete<void>(`/reports/${id}`),
    {
      onSuccess: () => {
        queryClient.invalidateQueries(REPORTS_QUERY_KEY)
      },
    }
  )
}

// Hook for report export
export function useExportReport() {
  return useMutation<Blob, Error, { id: string; format: 'pdf' | 'docx' }>(
    async ({ id, format }) => {
      const response = await fetch(`/api/v1/reports/${id}/export?format=${format}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('accessToken')}`,
        },
      })
      
      if (!response.ok) {
        throw new Error('Export failed')
      }
      
      return response.blob()
    }
  )
}