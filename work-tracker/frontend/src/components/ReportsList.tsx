import { useState } from 'react'
import { Report, ReportStatus, ReportType } from '@/types'
import { useReports, useDeleteReport } from '@/hooks/useReports'

interface ReportsListProps {
  onSelectReport?: (report: Report) => void
  selectedReportId?: string
}

export default function ReportsList({ onSelectReport, selectedReportId }: ReportsListProps) {
  const [currentPage, setCurrentPage] = useState(1)
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'all'>('all')
  const [typeFilter, setTypeFilter] = useState<ReportType | 'all'>('all')
  
  const { data: reportsData, isLoading, error } = useReports(currentPage, 10)
  const deleteReport = useDeleteReport()

  const handleDeleteReport = async (reportId: string) => {
    if (window.confirm('Are you sure you want to delete this report?')) {
      try {
        await deleteReport.mutateAsync(reportId)
      } catch (error) {
        console.error('Failed to delete report:', error)
        // TODO: Show error toast
      }
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  const getStatusBadge = (status: ReportStatus) => {
    const statusStyles = {
      [ReportStatus.DRAFT]: 'bg-gray-100 text-gray-800',
      [ReportStatus.GENERATING]: 'bg-yellow-100 text-yellow-800',
      [ReportStatus.COMPLETE]: 'bg-green-100 text-green-800',
      [ReportStatus.FAILED]: 'bg-red-100 text-red-800'
    }

    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${statusStyles[status]}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    )
  }

  const filteredReports = reportsData?.data?.filter(report => {
    const statusMatch = statusFilter === 'all' || report.status === statusFilter
    const typeMatch = typeFilter === 'all' || report.reportType === typeFilter
    return statusMatch && typeMatch
  }) || []

  if (isLoading) {
    return (
      <div className="card">
        <div className="animate-pulse space-y-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="flex items-center space-x-4">
              <div className="h-4 bg-gray-200 rounded w-1/4"></div>
              <div className="h-4 bg-gray-200 rounded w-1/2"></div>
              <div className="h-4 bg-gray-200 rounded w-1/4"></div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="card">
        <div className="text-center py-8">
          <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
            <svg className="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Failed to Load Reports</h3>
          <p className="text-gray-600">There was an error loading your reports. Please try again.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="card">
        <div className="flex items-center space-x-4">
          <div>
            <label htmlFor="statusFilter" className="block text-sm font-medium text-gray-700 mb-1">
              Status
            </label>
            <select
              id="statusFilter"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as ReportStatus | 'all')}
              className="input"
            >
              <option value="all">All Statuses</option>
              <option value={ReportStatus.DRAFT}>Draft</option>
              <option value={ReportStatus.GENERATING}>Generating</option>
              <option value={ReportStatus.COMPLETE}>Complete</option>
              <option value={ReportStatus.FAILED}>Failed</option>
            </select>
          </div>

          <div>
            <label htmlFor="typeFilter" className="block text-sm font-medium text-gray-700 mb-1">
              Type
            </label>
            <select
              id="typeFilter"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value as ReportType | 'all')}
              className="input"
            >
              <option value="all">All Types</option>
              <option value={ReportType.WEEKLY}>Weekly</option>
              <option value={ReportType.MONTHLY}>Monthly</option>
              <option value={ReportType.QUARTERLY}>Quarterly</option>
              <option value={ReportType.ANNUAL}>Annual</option>
              <option value={ReportType.CUSTOM}>Custom</option>
            </select>
          </div>
        </div>
      </div>

      {/* Reports List */}
      <div className="card">
        {filteredReports.length === 0 ? (
          <div className="text-center py-8">
            <svg className="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900">No reports found</h3>
            <p className="mt-1 text-sm text-gray-500">
              {statusFilter !== 'all' || typeFilter !== 'all' 
                ? 'No reports match your current filters.'
                : 'Get started by generating your first report.'
              }
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredReports.map((report) => (
              <div
                key={report.id}
                className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                  selectedReportId === report.id
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                }`}
                onClick={() => onSelectReport?.(report)}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h3 className="text-lg font-medium text-gray-900">{report.title}</h3>
                      {getStatusBadge(report.status)}
                    </div>
                    
                    <div className="flex items-center space-x-4 text-sm text-gray-600 mb-2">
                      <span className="capitalize">{report.reportType}</span>
                      <span>•</span>
                      <span>
                        {formatDate(report.periodStart)} - {formatDate(report.periodEnd)}
                      </span>
                      <span>•</span>
                      <span>{report.activitiesIncluded.length} activities</span>
                      {report.storiesIncluded.length > 0 && (
                        <>
                          <span>•</span>
                          <span>{report.storiesIncluded.length} stories</span>
                        </>
                      )}
                    </div>
                    
                    <p className="text-sm text-gray-500">
                      Generated {formatDate(report.createdAt)}
                      {report.generatedByAi && ' • AI Generated'}
                    </p>
                  </div>
                  
                  <div className="flex items-center space-x-2 ml-4">
                    <button
                      onClick={(e) => {
                        e.stopPropagation()
                        handleDeleteReport(report.id)
                      }}
                      disabled={deleteReport.isLoading}
                      className="text-red-600 hover:text-red-800 p-1"
                      title="Delete report"
                    >
                      <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Pagination */}
      {reportsData && reportsData.totalPages > 1 && (
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-700">
            Showing {((currentPage - 1) * 10) + 1} to {Math.min(currentPage * 10, reportsData.total)} of {reportsData.total} reports
          </div>
          
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
              disabled={currentPage === 1}
              className="btn btn-secondary disabled:opacity-50"
            >
              Previous
            </button>
            
            <span className="text-sm text-gray-700">
              Page {currentPage} of {reportsData.totalPages}
            </span>
            
            <button
              onClick={() => setCurrentPage(prev => Math.min(reportsData.totalPages, prev + 1))}
              disabled={currentPage === reportsData.totalPages}
              className="btn btn-secondary disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  )
}