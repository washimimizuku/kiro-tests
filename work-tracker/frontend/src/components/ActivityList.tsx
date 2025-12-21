import { useState } from 'react'
import { format, parseISO } from 'date-fns'
import { Edit2, Trash2, Calendar, Clock, Tag } from 'lucide-react'
import { Activity, ActivityCategory } from '@/types'
import { useDeleteActivity } from '@/hooks/useActivities'
import toast from 'react-hot-toast'

interface ActivityListProps {
  activities: Activity[]
  onEdit?: (activity: Activity) => void
  isLoading?: boolean
}

const categoryLabels: Record<ActivityCategory, string> = {
  [ActivityCategory.CUSTOMER_ENGAGEMENT]: 'Customer Engagement',
  [ActivityCategory.LEARNING]: 'Learning',
  [ActivityCategory.SPEAKING]: 'Speaking',
  [ActivityCategory.MENTORING]: 'Mentoring',
  [ActivityCategory.TECHNICAL_CONSULTATION]: 'Technical Consultation',
  [ActivityCategory.CONTENT_CREATION]: 'Content Creation',
}

const categoryColors: Record<ActivityCategory, string> = {
  [ActivityCategory.CUSTOMER_ENGAGEMENT]: 'bg-blue-100 text-blue-800',
  [ActivityCategory.LEARNING]: 'bg-green-100 text-green-800',
  [ActivityCategory.SPEAKING]: 'bg-purple-100 text-purple-800',
  [ActivityCategory.MENTORING]: 'bg-yellow-100 text-yellow-800',
  [ActivityCategory.TECHNICAL_CONSULTATION]: 'bg-red-100 text-red-800',
  [ActivityCategory.CONTENT_CREATION]: 'bg-indigo-100 text-indigo-800',
}

const impactLevelColors = {
  1: 'bg-gray-100 text-gray-800',
  2: 'bg-yellow-100 text-yellow-800',
  3: 'bg-blue-100 text-blue-800',
  4: 'bg-orange-100 text-orange-800',
  5: 'bg-red-100 text-red-800',
}

export default function ActivityList({ activities, onEdit, isLoading }: ActivityListProps) {
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const deleteActivity = useDeleteActivity()

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this activity?')) {
      return
    }

    try {
      setDeletingId(id)
      await deleteActivity.mutateAsync(id)
      toast.success('Activity deleted successfully')
    } catch (error) {
      toast.error('Failed to delete activity')
    } finally {
      setDeletingId(null)
    }
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        {[...Array(3)].map((_, i) => (
          <div key={i} className="card animate-pulse">
            <div className="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
            <div className="h-3 bg-gray-200 rounded w-1/2 mb-4"></div>
            <div className="flex gap-2">
              <div className="h-6 bg-gray-200 rounded w-20"></div>
              <div className="h-6 bg-gray-200 rounded w-16"></div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (activities.length === 0) {
    return (
      <div className="card text-center py-12">
        <Calendar className="mx-auto h-12 w-12 text-gray-400 mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">No activities found</h3>
        <p className="text-gray-500">
          Start by logging your first activity using the form above.
        </p>
      </div>
    )
  }

  // Group activities by date
  const groupedActivities = activities.reduce((groups, activity) => {
    const date = activity.date
    if (!groups[date]) {
      groups[date] = []
    }
    groups[date].push(activity)
    return groups
  }, {} as Record<string, Activity[]>)

  return (
    <div className="space-y-6">
      {Object.entries(groupedActivities)
        .sort(([a], [b]) => new Date(b).getTime() - new Date(a).getTime())
        .map(([date, dateActivities]) => (
          <div key={date}>
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Calendar size={20} />
              {format(parseISO(date), 'EEEE, MMMM d, yyyy')}
            </h3>
            <div className="space-y-4">
              {dateActivities.map((activity) => (
                <div key={activity.id} className="card hover:shadow-md transition-shadow">
                  <div className="flex justify-between items-start mb-3">
                    <div className="flex-1">
                      <h4 className="text-lg font-medium text-gray-900 mb-1">
                        {activity.title}
                      </h4>
                      {activity.description && (
                        <p className="text-gray-600 mb-3">{activity.description}</p>
                      )}
                    </div>
                    <div className="flex items-center gap-2 ml-4">
                      {onEdit && (
                        <button
                          onClick={() => onEdit(activity)}
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit activity"
                        >
                          <Edit2 size={16} />
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(activity.id)}
                        disabled={deletingId === activity.id}
                        className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
                        title="Delete activity"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-3 text-sm">
                    {/* Category */}
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        categoryColors[activity.category]
                      }`}
                    >
                      {categoryLabels[activity.category]}
                    </span>

                    {/* Impact Level */}
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        impactLevelColors[activity.impactLevel as keyof typeof impactLevelColors]
                      }`}
                    >
                      Impact: {activity.impactLevel}/5
                    </span>

                    {/* Duration */}
                    {activity.durationMinutes && (
                      <span className="inline-flex items-center gap-1 text-gray-500">
                        <Clock size={14} />
                        {activity.durationMinutes}m
                      </span>
                    )}

                    {/* Tags */}
                    {activity.tags.length > 0 && (
                      <div className="flex items-center gap-1">
                        <Tag size={14} className="text-gray-400" />
                        <div className="flex flex-wrap gap-1">
                          {activity.tags.map((tag) => (
                            <span
                              key={tag}
                              className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-gray-100 text-gray-700"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
    </div>
  )
}