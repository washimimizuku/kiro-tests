import { useState } from 'react'
import { Report, ReportStatus } from '@/types'
import { useExportReport } from '@/hooks/useReports'

interface ReportViewerProps {
  report: Report
  onEdit?: () => void
  onRegenerate?: () => void
  onClose?: () => void
}

export default function ReportViewer({ report, onEdit, onRegenerate, onClose }: ReportViewerProps) {
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [exportFormat, setExportFormat] = useState<'pdf' | 'docx'>('pdf')
  const exportReport = useExportReport()

  const handleExport = async (format: 'pdf' | 'docx') => {
    try {
      const blob = await exportReport.mutateAsync({ id: report.id, format })
      
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `${report.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.${format}`
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
    const shareData = {
      title: report.title,
      text: `Check out my ${report.reportType} report: ${report.title}`,
      url: window.location.href
    }

    if (navigator.share && navigator.canShare(shareData)) {
      try {
        await navigator.share(shareData)
      } catch (error) {
        console.error('Share failed:', error)
      }
    } else {
      // Fallback: copy link to clipboard
      try {
        await navigator.clipboard.writeText(window.location.href)
        // TODO: Show success toast
      } catch (error) {
        console.error('Copy to clipboard failed:', error)
      }
    }
  }

  const handlePrint = () => {
    const printWindow = window.open('', '_blank')
    if (printWindow) {
      printWindow.document.write(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>${report.title}</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
              h1 { color: #1f2937; border-bottom: 2px solid #e5e7eb; padding-bottom: 10px; }
              h2 { color: #374151; margin-top: 30px; }
              h3 { color: #4b5563; margin-top: 20px; }
              p { margin-bottom: 15px; }
              ul { margin-bottom: 15px; }
              li { margin-bottom: 5px; }
              .report-meta { background: #f9fafb; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
              .report-meta h3 { margin-top: 0; }
              @media print {
                body { margin: 20px; }
                .no-print { display: none; }
              }
            </style>
          </head>
          <body>
            <div class="report-meta">
              <h3>Report Details</h3>
              <p><strong>Period:</strong> ${new Date(report.periodStart).toLocaleDateString()} - ${new Date(report.periodEnd).toLocaleDateString()}</p>
              <p><strong>Type:</strong> ${report.reportType.charAt(0).toUpperCase() + report.reportType.slice(1)}</p>
              <p><strong>Generated:</strong> ${new Date(report.createdAt).toLocaleDateString()}</p>
              <p><strong>Activities:</strong> ${report.activitiesIncluded.length}</p>
              <p><strong>Stories:</strong> ${report.storiesIncluded.length}</p>
            </div>
            ${report.content || '<p>Report content is being generated...</p>'}
          </body>
        </html>
      `)
      printWindow.document.close()
      printWindow.print()
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
          <div className="flex justify-center space-x-3">
            {onRegenerate && (
              <button onClick={onRegenerate} className="btn btn-primary">
                Try Again
              </button>
            )}
            {onClose && (
              <button onClick={onClose} className="btn btn-secondary">
                Close
              </button>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className={`space-y-6 ${isFullscreen ? 'fixed inset-0 z-50 bg-white overflow-auto p-6' : ''}`}>
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
            <button
              onClick={() => setIsFullscreen(!isFullscreen)}
              className="btn btn-secondary"
              title={isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen'}
            >
              {isFullscreen ? (
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              ) : (
                <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
                </svg>
              )}
            </button>
            
            {onClose && (
              <button onClick={onClose} className="btn btn-secondary">
                Close
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Report Actions */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Actions</h3>
            <p className="text-gray-600">Export, share, or modify your report</p>
          </div>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Export Section */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Export Format</label>
            <select
              value={exportFormat}
              onChange={(e) => setExportFormat(e.target.value as 'pdf' | 'docx')}
              className="input"
            >
              <option value="pdf">PDF Document</option>
              <option value="docx">Word Document</option>
            </select>
            <button
              onClick={() => handleExport(exportFormat)}
              disabled={exportReport.isLoading}
              className="btn btn-primary w-full"
            >
              {exportReport.isLoading ? 'Exporting...' : `Export ${exportFormat.toUpperCase()}`}
            </button>
          </div>

          {/* Print Section */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Print</label>
            <div className="h-10"></div> {/* Spacer to align with export */}
            <button
              onClick={handlePrint}
              className="btn btn-secondary w-full"
            >
              Print Report
            </button>
          </div>

          {/* Share Section */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Share</label>
            <div className="h-10"></div> {/* Spacer to align with export */}
            <button
              onClick={handleShare}
              className="btn btn-secondary w-full"
            >
              Share Report
            </button>
          </div>

          {/* Edit Section */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-gray-700">Modify</label>
            <div className="flex space-x-2">
              {onEdit && (
                <button onClick={onEdit} className="btn btn-secondary flex-1">
                  Edit
                </button>
              )}
              {onRegenerate && (
                <button onClick={onRegenerate} className="btn btn-secondary flex-1">
                  Regenerate
                </button>
              )}
            </div>
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
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 text-sm">
          <div className="bg-gray-50 p-3 rounded">
            <span className="font-medium text-gray-700 block">Activities Included</span>
            <span className="text-2xl font-bold text-blue-600">{report.activitiesIncluded.length}</span>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <span className="font-medium text-gray-700 block">Stories Included</span>
            <span className="text-2xl font-bold text-green-600">{report.storiesIncluded.length}</span>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <span className="font-medium text-gray-700 block">Report Type</span>
            <span className="text-lg font-semibold text-gray-900 capitalize">{report.reportType}</span>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <span className="font-medium text-gray-700 block">Generated By</span>
            <span className="text-lg font-semibold text-gray-900">{report.generatedByAi ? 'AI Assistant' : 'Manual'}</span>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <span className="font-medium text-gray-700 block">Created</span>
            <span className="text-lg font-semibold text-gray-900">{formatDate(report.createdAt)}</span>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <span className="font-medium text-gray-700 block">Status</span>
            <span className="text-lg font-semibold text-gray-900 capitalize">{report.status}</span>
          </div>
        </div>
      </div>
    </div>
  )
}