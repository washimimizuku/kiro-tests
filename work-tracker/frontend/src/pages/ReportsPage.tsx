import { useState } from 'react'
import { Report, ReportGenerateRequest } from '@/types'
import { useGenerateReport } from '@/hooks/useReports'
import ReportGenerationForm from '@/components/ReportGenerationForm'
import ReportViewer from '@/components/ReportViewer'
import ReportsList from '@/components/ReportsList'

type ViewMode = 'list' | 'generate' | 'preview'

export default function ReportsPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('list')
  const [selectedReport, setSelectedReport] = useState<Report | null>(null)
  
  const generateReport = useGenerateReport()

  const handleGenerateReport = async (data: ReportGenerateRequest) => {
    try {
      const report = await generateReport.mutateAsync(data)
      setSelectedReport(report)
      setViewMode('preview')
    } catch (error) {
      console.error('Failed to generate report:', error)
      // TODO: Show error toast
    }
  }

  const handleSelectReport = (report: Report) => {
    setSelectedReport(report)
    setViewMode('preview')
  }

  const handleEditReport = () => {
    // TODO: Implement report editing
    setViewMode('generate')
  }

  const handleRegenerateReport = () => {
    if (selectedReport) {
      const regenerateData: ReportGenerateRequest = {
        title: selectedReport.title,
        periodStart: selectedReport.periodStart,
        periodEnd: selectedReport.periodEnd,
        reportType: selectedReport.reportType,
        includeActivities: selectedReport.activitiesIncluded,
        includeStories: selectedReport.storiesIncluded
      }
      handleGenerateReport(regenerateData)
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Reports</h1>
          <p className="mt-2 text-gray-600">
            Generate AI-powered activity reports for different time periods
          </p>
        </div>
        
        <div className="flex items-center space-x-3">
          <button
            onClick={() => setViewMode('list')}
            className={`btn ${viewMode === 'list' ? 'btn-primary' : 'btn-secondary'}`}
          >
            View Reports
          </button>
          <button
            onClick={() => setViewMode('generate')}
            className={`btn ${viewMode === 'generate' ? 'btn-primary' : 'btn-secondary'}`}
          >
            Generate New
          </button>
        </div>
      </div>

      {/* Content */}
      {viewMode === 'list' && (
        <ReportsList 
          onSelectReport={handleSelectReport}
          selectedReportId={selectedReport?.id}
        />
      )}

      {viewMode === 'generate' && (
        <div className="max-w-4xl">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-gray-900">Generate New Report</h2>
            <p className="text-gray-600">
              Configure your report settings and let AI analyze your activities
            </p>
          </div>
          
          <ReportGenerationForm
            onSubmit={handleGenerateReport}
            isLoading={generateReport.isLoading}
          />
        </div>
      )}

      {viewMode === 'preview' && selectedReport && (
        <div>
          <div className="mb-6 flex items-center space-x-4">
            <button
              onClick={() => setViewMode('list')}
              className="btn btn-secondary"
            >
              ← Back to Reports
            </button>
          </div>
          
          <ReportViewer
            report={selectedReport}
            onEdit={handleEditReport}
            onRegenerate={handleRegenerateReport}
            onClose={() => setViewMode('list')}
          />
        </div>
      )}
    </div>
  )
}