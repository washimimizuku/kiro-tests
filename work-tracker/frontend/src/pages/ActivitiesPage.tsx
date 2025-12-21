import { useState } from 'react'
import { Plus } from 'lucide-react'
import ActivityForm from '@/components/ActivityForm'
import ActivityList from '@/components/ActivityList'
import ActivityFilters from '@/components/ActivityFilters'
import ActivityDetail from '@/components/ActivityDetail'
import { useCreateActivity, useActivities } from '@/hooks/useActivities'
import { ActivityCreateRequest, ActivityFilters as ActivityFiltersType, Activity } from '@/types'

export default function ActivitiesPage() {
  const [showForm, setShowForm] = useState(false)
  const [filters, setFilters] = useState<ActivityFiltersType>({})
  const [selectedActivity, setSelectedActivity] = useState<Activity | null>(null)
  const [currentPage, setCurrentPage] = useState(1)
  
  const createActivity = useCreateActivity()
  const { data: activitiesData, isLoading } = useActivities(filters, currentPage, 20)

  const handleCreateActivity = async (data: ActivityCreateRequest) => {
    await createActivity.mutateAsync(data)
    setShowForm(false)
  }

  const handleEditActivity = (activity: Activity) => {
    setSelectedActivity(activity)
  }

  const handleFiltersChange = (newFilters: ActivityFiltersType) => {
    setFilters(newFilters)
    setCurrentPage(1) // Reset to first page when filters change
  }

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Activities</h1>
          <p className="mt-2 text-gray-600">
            Log and manage your professional activities
          </p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          <Plus size={20} />
          {showForm ? 'Cancel' : 'Log Activity'}
        </button>
      </div>

      {/* Quick Activity Form */}
      {showForm && (
        <div className="card">
          <div className="border-b border-gray-200 pb-4 mb-6">
            <h2 className="text-xl font-semibold text-gray-900">Log New Activity</h2>
            <p className="text-gray-600">Quickly capture your professional activities</p>
          </div>
          <ActivityForm
            onSubmit={handleCreateActivity}
            isLoading={createActivity.isLoading}
          />
        </div>
      )}

      {/* Filters */}
      <ActivityFilters
        filters={filters}
        onFiltersChange={handleFiltersChange}
      />

      {/* Activity List */}
      <div>
        {activitiesData && (
          <div className="mb-4 text-sm text-gray-600">
            Showing {activitiesData.data.length} of {activitiesData.total} activities
            {activitiesData.totalPages > 1 && (
              <span> (Page {activitiesData.page} of {activitiesData.totalPages})</span>
            )}
          </div>
        )}
        
        <ActivityList
          activities={activitiesData?.data || []}
          onEdit={handleEditActivity}
          isLoading={isLoading}
        />

        {/* Pagination */}
        {activitiesData && activitiesData.totalPages > 1 && (
          <div className="flex justify-center items-center gap-2 mt-8">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            
            <div className="flex gap-1">
              {Array.from({ length: Math.min(5, activitiesData.totalPages) }, (_, i) => {
                const page = i + 1
                return (
                  <button
                    key={page}
                    onClick={() => setCurrentPage(page)}
                    className={`px-3 py-2 text-sm rounded-lg ${
                      currentPage === page
                        ? 'bg-blue-600 text-white'
                        : 'bg-white border border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    {page}
                  </button>
                )
              })}
            </div>
            
            <button
              onClick={() => setCurrentPage(Math.min(activitiesData.totalPages, currentPage + 1))}
              disabled={currentPage === activitiesData.totalPages}
              className="px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        )}
      </div>

      {/* Activity Detail Modal */}
      {selectedActivity && (
        <ActivityDetail
          activity={selectedActivity}
          isOpen={!!selectedActivity}
          onClose={() => setSelectedActivity(null)}
        />
      )}
    </div>
  )
}