import { Activity, BookOpen, FileText, Plus } from 'lucide-react'

export default function HomePage() {
  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">
          Track your professional activities and create impactful stories
        </p>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card hover:shadow-md transition-shadow cursor-pointer">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <Plus className="h-8 w-8 text-primary-600" />
            </div>
            <div className="ml-4">
              <h3 className="text-lg font-medium text-gray-900">Log Activity</h3>
              <p className="text-sm text-gray-500">Quick entry for daily work</p>
            </div>
          </div>
        </div>

        <div className="card hover:shadow-md transition-shadow cursor-pointer">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <BookOpen className="h-8 w-8 text-primary-600" />
            </div>
            <div className="ml-4">
              <h3 className="text-lg font-medium text-gray-900">Create Story</h3>
              <p className="text-sm text-gray-500">Document customer success</p>
            </div>
          </div>
        </div>

        <div className="card hover:shadow-md transition-shadow cursor-pointer">
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <FileText className="h-8 w-8 text-primary-600" />
            </div>
            <div className="ml-4">
              <h3 className="text-lg font-medium text-gray-900">Generate Report</h3>
              <p className="text-sm text-gray-500">AI-powered summaries</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="card">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Recent Activity</h2>
        <div className="space-y-4">
          <div className="flex items-center space-x-3">
            <Activity className="h-5 w-5 text-gray-400" />
            <div>
              <p className="text-sm font-medium text-gray-900">Customer consultation</p>
              <p className="text-sm text-gray-500">2 hours ago</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <BookOpen className="h-5 w-5 text-gray-400" />
            <div>
              <p className="text-sm font-medium text-gray-900">Updated success story</p>
              <p className="text-sm text-gray-500">1 day ago</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <FileText className="h-5 w-5 text-gray-400" />
            <div>
              <p className="text-sm font-medium text-gray-900">Generated monthly report</p>
              <p className="text-sm text-gray-500">3 days ago</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}