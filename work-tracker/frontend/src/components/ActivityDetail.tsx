import { useState } from 'react'
import { format, parseISO } from 'date-fns'
import { X, Edit2, Calendar, Clock, Tag, BarChart3 } from 'lucide-react'
import { Activity, ActivityCategory, ActivityCreateRequest } from '@/types'
import { useUpdateActivity } from '@/hooks/useActivities'
import ActivityForm from './ActivityForm'
import toast from 'react-hot-toast'

interface ActivityDetailProps {
  activity: Activity
  isOpen: boolean
  onClose: () => void
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

export default function ActivityDetail({ activity, isOpen, onClose }: ActivityDetailProps) {
  const [isEditing, setIsEditing] = useState(false)
  const updateActivity = useUpdateActivity()

  const handleUpdate = async (data: ActivityCreateRequest) => {
    try {
      await updateActivity.mutateAsync({ id: activity.id, data })
      setIsEditing(false)
      toast.success('Activity updated successfully!')
    } catch (error) {
      toast.error('Failed to update activity')
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-screen items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
          onClick={onClose}
        />

        {/* Modal */}
        <div className="relative bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900">
              {isEditing ? 'Edit Activity' : 'Activity Details'}
            </h2>
            <div className="flex items-center gap-2">
              {!isEditing && (
                <button
                  onClick={() => setIsEditing(true)}
                  className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  title="Edit activity"
                >
                  <Edit2 size={20} />
                </button>
              )}
              <button
                onClick={onClose}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X size={20} />
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="p-6">
            {isEditing ? (
              <div>
                <ActivityForm
                  onSubmit={handleUpdate}
                  initialData={{
                    title: activity.title,
                    description: activity.description,
                    category: activity.category,
                    tags: activity.tags,
                    impactLevel: activity.impactLevel,
                    date: activity.date,
                    durationMinutes: activity.durationMinutes,
                  }}
                  isLoading={updateActivity.isLoading}
                />
                <div className="flex justify-end gap-3 mt-6 pt-6 border-t border-gray-200">
                  <button
                    onClick={() => setIsEditing(false)}
                    className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                {/* Title and Description */}
                <div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-2">
                    {activity.title}
                  </h3>
                  {activity.description && (
                    <p className="text-gray-600 leading-relaxed">
                      {activity.description}
                    </p>
                  )}
                </div>

                {/* Metadata Grid */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Date */}
                  <div className="flex items-center gap-3">
                    <Calendar className="text-gray-400" size={20} />
                    <div>
                      <p className="text-sm text-gray-500">Date</p>
                      <p className="font-medium text-gray-900">
                        {format(parseISO(activity.date), 'EEEE, MMMM d, yyyy')}
                      </p>
                    </div>
                  </div>

                  {/* Duration */}
                  {activity.durationMinutes && (
                    <div className="flex items-center gap-3">
                      <Clock className="text-gray-400" size={20} />
                      <div>
                        <p className="text-sm text-gray-500">Duration</p>
                        <p className="font-medium text-gray-900">
                          {activity.durationMinutes} minutes
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Impact Level */}
                  <div className="flex items-center gap-3">
                    <BarChart3 className="text-gray-400" size={20} />
                    <div>
                      <p className="text-sm text-gray-500">Impact Level</p>
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium ${
                          impactLevelColors[activity.impactLevel as keyof typeof impactLevelColors]
                        }`}
                      >
                        {activity.impactLevel}/5
                      </span>
                    </div>
                  </div>

                  {/* Category */}
                  <div className="flex items-center gap-3">
                    <div className="w-5 h-5 rounded-full bg-gray-400" />
                    <div>
                      <p className="text-sm text-gray-500">Category</p>
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium ${
                          categoryColors[activity.category]
                        }`}
                      >
                        {categoryLabels[activity.category]}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Tags */}
                {activity.tags.length > 0 && (
                  <div>
                    <div className="flex items-center gap-2 mb-3">
                      <Tag className="text-gray-400" size={20} />
                      <p className="text-sm text-gray-500">Tags</p>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {activity.tags.map((tag) => (
                        <span
                          key={tag}
                          className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-gray-100 text-gray-700"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Metadata */}
                {Object.keys(activity.metadata).length > 0 && (
                  <div>
                    <h4 className="text-lg font-medium text-gray-900 mb-3">
                      Additional Information
                    </h4>
                    <div className="bg-gray-50 rounded-lg p-4">
                      <pre className="text-sm text-gray-600 whitespace-pre-wrap">
                        {JSON.stringify(activity.metadata, null, 2)}
                      </pre>
                    </div>
                  </div>
                )}

                {/* Timestamps */}
                <div className="pt-6 border-t border-gray-200">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm text-gray-500">
                    <div>
                      <p>Created: {format(parseISO(activity.createdAt), 'PPp')}</p>
                    </div>
                    <div>
                      <p>Updated: {format(parseISO(activity.updatedAt), 'PPp')}</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}