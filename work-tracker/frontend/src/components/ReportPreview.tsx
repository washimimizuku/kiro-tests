import { Report, ReportStatus } from '@/types'
import { useExportReport } from '@/hooks/useReports'

interface ReportPreviewProps {
  report: Report
  onEdit?: () => void
  onRegenerate?: () => void
}

export default function ReportPreview({ report, onEdit, onRegenerate }: ReportPreviewProps) {
  const exportReport = useExportReport()

  const handleExport = async (format: 'pdf' | 'docx') => {
    try {
      const blob = await exportReport.mutateAsync({ id: report.id, format })
      
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `${report.title}.${format}`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
    } catch (error) {
      console.error('Export failed:', error)
      // TODO: Show error toast
    }
  }

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: report.title,
          text: `Check out my ${report.reportType} report: ${report.title}`,
          url: window.location.href
        })
      } catch (error) {
        console.error('Share failed:', error)
      }
    } else {
      // Fallback: copy link to clipboard
      navigator.clipboard.writeText(window.location.href)
      // TODO: Show success toast
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
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

  if (report.status === ReportStatus.GENERATING) {
    return (
      <div className="card">
        <div className="flex items-center justify-center py-12">
          <div className="text-center">
            <svg className="animate-spin h-12 w-12 text-blue-600 mx-auto mb-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <h3 className="text-lg font-medium text-gray-900 mb-2">Generating Report</h3>
            <p className="text-gray-600">AI is analyzing your activities and creating your report...</p>
          </div>
        </div>
      </div>
    )
  }

  if (report.status === ReportStatus.FAILED) {
    return (
      <div className="card">
        <div className="text-center py-12">
          <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
            <svg className="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">Report Generation Failed</h3>
          <p className="text-gray-600 mb-4">There was an error generating your report. Please try again.</p>
          {onRegenerate && (
            <button onClick={onRegenerate} className="btn btn-primary">
              Try Again
            </button>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Report Header */}
      <div className="card">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <div className="flex items-center space-x-3 mb-2">
              <h2 className="text-2xl font-bold text-gray-900">{report.title}</h2>
              {getStatusBadge(report.status)}
            </div>
            <div className="flex items-center space-x-4 text-sm text-gray-600">
              <span>
                {formatDate(report.periodStart)} - {formatDate(report.periodEnd)}
              </span>
              <span>•</span>
              <span className="capitalize">{report.reportType} Report</span>
              <span>•</span>
              <span>Generated {formatDate(report.createdAt)}</span>
              {report.generatedByAi && (
                <>
                  <span>•</span>
                  <span className="text-blue-600">AI Generated</span>
                </>
              )}
            </div>
          </div>
          
          <div className="flex items-center space-x-2">
            {onEdit && (
              <button onClick={onEdit} className="btn btn-secondary">
                Edit
              </button>
            )}
            {onRegenerate && (
              <button onClick={onRegenerate} className="btn btn-secondary">
                Regenerate
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Report Actions */}
      <div className="card">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Export & Share</h3>
            <p className="text-gray-600">Download your report or share it with others</p>
          </div>
          
          <div className="flex items-center space-x-3">
            <button
              onClick={() => handleExport('pdf')}
              disabled={exportReport.isLoading}
              className="btn btn-secondary"
            >
              {exportReport.isLoading ? 'Exporting...' : 'Export PDF'}
            </button>
            
            <button
              onClick={() => handleExport('docx')}
              disabled={exportReport.isLoading}
              className="btn btn-secondary"
            >
              {exportReport.isLoading ? 'Exporting...' : 'Export Word'}
            </button>
            
            <button
              onClick={handleShare}
              className="btn btn-secondary"
            >
              Share
            </button>
          </div>
        </div>
      </div>

      {/* Report Content */}
      <div className="card">
        <div className="prose max-w-none">
          {report.content ? (
            <div 
              dangerouslySetInnerHTML={{ __html: report.content }}
              className="report-content"
            />
          ) : (
            <div className="text-center py-8 text-gray-500">
              <p>Report content is being generated...</p>
            </div>
          )}
        </div>
      </div>

      {/* Report Metadata */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Report Details</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span className="font-medium text-gray-700">Activities Included:</span>
            <span className="ml-2 text-gray-600">{report.activitiesIncluded.length}</span>
          </div>
          <div>
            <span className="font-medium text-gray-700">Stories Included:</span>
            <span className="ml-2 text-gray-600">{report.storiesIncluded.length}</span>
          </div>
          <div>
            <span className="font-medium text-gray-700">Report Type:</span>
            <span className="ml-2 text-gray-600 capitalize">{report.reportType}</span>
          </div>
          <div>
            <span className="font-medium text-gray-700">Generated By:</span>
            <span className="ml-2 text-gray-600">{report.generatedByAi ? 'AI Assistant' : 'Manual'}</span>
          </div>
        </div>
      </div>
    </div>
  )
}