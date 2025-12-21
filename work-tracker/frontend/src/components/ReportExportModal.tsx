import { useState } from 'react'
import { Report } from '@/types'
import { useExportReport } from '@/hooks/useReports'

interface ReportExportModalProps {
  report: Report
  isOpen: boolean
  onClose: () => void
}

interface ExportOptions {
  format: 'pdf' | 'docx'
  includeMetadata: boolean
  includeCharts: boolean
  pageSize: 'letter' | 'a4'
  orientation: 'portrait' | 'landscape'
  fontSize: 'small' | 'medium' | 'large'
}

export default function ReportExportModal({ report, isOpen, onClose }: ReportExportModalProps) {
  const [exportOptions, setExportOptions] = useState<ExportOptions>({
    format: 'pdf',
    includeMetadata: true,
    includeCharts: true,
    pageSize: 'letter',
    orientation: 'portrait',
    fontSize: 'medium'
  })
  
  const exportReport = useExportReport()

  const handleExport = async () => {
    try {
      // For now, we'll use the basic export functionality
      // In a real implementation, these options would be sent to the backend
      const blob = await exportReport.mutateAsync({ 
        id: report.id, 
        format: exportOptions.format 
      })
      
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `${report.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.${exportOptions.format}`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
      
      onClose()
    } catch (error) {
      console.error('Export failed:', error)
      // TODO: Show error toast
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        {/* Background overlay */}
        <div 
          className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
          onClick={onClose}
        ></div>

        {/* Modal */}
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            <div className="sm:flex sm:items-start">
              <div className="mt-3 text-center sm:mt-0 sm:text-left w-full">
                <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
                  Export Report: {report.title}
                </h3>
                
                <div className="space-y-4">
                  {/* Format Selection */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Export Format
                    </label>
                    <div className="grid grid-cols-2 gap-3">
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="format"
                          value="pdf"
                          checked={exportOptions.format === 'pdf'}
                          onChange={(e) => setExportOptions(prev => ({ ...prev, format: e.target.value as 'pdf' | 'docx' }))}
                          className="mr-2"
                        />
                        <span className="text-sm">PDF Document</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="radio"
                          name="format"
                          value="docx"
                          checked={exportOptions.format === 'docx'}
                          onChange={(e) => setExportOptions(prev => ({ ...prev, format: e.target.value as 'pdf' | 'docx' }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Word Document</span>
                      </label>
                    </div>
                  </div>

                  {/* Page Settings (PDF only) */}
                  {exportOptions.format === 'pdf' && (
                    <>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Page Size
                        </label>
                        <select
                          value={exportOptions.pageSize}
                          onChange={(e) => setExportOptions(prev => ({ ...prev, pageSize: e.target.value as 'letter' | 'a4' }))}
                          className="input"
                        >
                          <option value="letter">Letter (8.5" × 11")</option>
                          <option value="a4">A4 (210 × 297 mm)</option>
                        </select>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                          Orientation
                        </label>
                        <div className="grid grid-cols-2 gap-3">
                          <label className="flex items-center">
                            <input
                              type="radio"
                              name="orientation"
                              value="portrait"
                              checked={exportOptions.orientation === 'portrait'}
                              onChange={(e) => setExportOptions(prev => ({ ...prev, orientation: e.target.value as 'portrait' | 'landscape' }))}
                              className="mr-2"
                            />
                            <span className="text-sm">Portrait</span>
                          </label>
                          <label className="flex items-center">
                            <input
                              type="radio"
                              name="orientation"
                              value="landscape"
                              checked={exportOptions.orientation === 'landscape'}
                              onChange={(e) => setExportOptions(prev => ({ ...prev, orientation: e.target.value as 'portrait' | 'landscape' }))}
                              className="mr-2"
                            />
                            <span className="text-sm">Landscape</span>
                          </label>
                        </div>
                      </div>
                    </>
                  )}

                  {/* Font Size */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Font Size
                    </label>
                    <select
                      value={exportOptions.fontSize}
                      onChange={(e) => setExportOptions(prev => ({ ...prev, fontSize: e.target.value as 'small' | 'medium' | 'large' }))}
                      className="input"
                    >
                      <option value="small">Small</option>
                      <option value="medium">Medium</option>
                      <option value="large">Large</option>
                    </select>
                  </div>

                  {/* Content Options */}
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Include Options
                    </label>
                    <div className="space-y-2">
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          checked={exportOptions.includeMetadata}
                          onChange={(e) => setExportOptions(prev => ({ ...prev, includeMetadata: e.target.checked }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Include report metadata (dates, statistics)</span>
                      </label>
                      <label className="flex items-center">
                        <input
                          type="checkbox"
                          checked={exportOptions.includeCharts}
                          onChange={(e) => setExportOptions(prev => ({ ...prev, includeCharts: e.target.checked }))}
                          className="mr-2"
                        />
                        <span className="text-sm">Include charts and visualizations</span>
                      </label>
                    </div>
                  </div>

                  {/* Preview Info */}
                  <div className="bg-blue-50 p-3 rounded-md">
                    <div className="flex">
                      <svg className="h-5 w-5 text-blue-400 mr-2" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                      </svg>
                      <div className="text-sm text-blue-700">
                        <p className="font-medium">Export Preview</p>
                        <p>
                          Format: {exportOptions.format.toUpperCase()}
                          {exportOptions.format === 'pdf' && ` • ${exportOptions.pageSize.toUpperCase()} ${exportOptions.orientation}`}
                          • {exportOptions.fontSize} font
                        </p>
                        <p>
                          Content: {report.activitiesIncluded.length} activities, {report.storiesIncluded.length} stories
                          {exportOptions.includeMetadata && ', metadata'}
                          {exportOptions.includeCharts && ', charts'}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              onClick={handleExport}
              disabled={exportReport.isLoading}
              className="btn btn-primary sm:ml-3 sm:w-auto"
            >
              {exportReport.isLoading ? 'Exporting...' : 'Export Report'}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="btn btn-secondary mt-3 sm:mt-0 sm:w-auto"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}