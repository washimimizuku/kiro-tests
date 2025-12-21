import { useState, useEffect } from 'react'
import { Story, StoryCreateRequest, StoryStatus } from '@/types'
import { useCreateStory, useUpdateStory, useStory } from '@/hooks/useStories'
import StoryForm from './StoryForm'
import { ArrowLeft, Save, Eye, EyeOff } from 'lucide-react'
import toast from 'react-hot-toast'

interface StoryEditorProps {
  storyId?: string
  onBack?: () => void
  onSave?: (story: Story) => void
}

export default function StoryEditor({ storyId, onBack, onSave }: StoryEditorProps) {
  const [showPreview, setShowPreview] = useState(false)
  const [previewData, setPreviewData] = useState<StoryCreateRequest | null>(null)

  const isEditing = !!storyId
  const { data: story, isLoading: isLoadingStory } = useStory(storyId || '')
  const createStory = useCreateStory()
  const updateStory = useUpdateStory()

  const isLoading = createStory.isLoading || updateStory.isLoading

  const handleSubmit = async (data: StoryCreateRequest) => {
    try {
      let savedStory: Story

      if (isEditing && storyId) {
        savedStory = await updateStory.mutateAsync({ id: storyId, data })
      } else {
        savedStory = await createStory.mutateAsync(data)
      }

      onSave?.(savedStory)
    } catch (error) {
      // Error handling is done in the form component
      throw error
    }
  }

  const handlePreview = (data: StoryCreateRequest) => {
    setPreviewData(data)
    setShowPreview(true)
  }

  if (isLoadingStory) {
    return (
      <div className="space-y-8">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="h-4 bg-gray-200 rounded w-2/3 mb-8"></div>
          <div className="space-y-6">
            {[...Array(5)].map((_, i) => (
              <div key={i}>
                <div className="h-4 bg-gray-200 rounded w-1/4 mb-2"></div>
                <div className="h-24 bg-gray-200 rounded"></div>
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  if (showPreview && previewData) {
    return (
      <StoryPreview
        data={previewData}
        onBack={() => setShowPreview(false)}
        onEdit={() => setShowPreview(false)}
      />
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          {onBack && (
            <button
              onClick={onBack}
              className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ArrowLeft size={20} />
            </button>
          )}
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              {isEditing ? 'Edit Story' : 'Create New Story'}
            </h1>
            {story && (
              <div className="flex items-center gap-2 mt-1">
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                  story.status === StoryStatus.PUBLISHED
                    ? 'bg-green-100 text-green-800'
                    : story.status === StoryStatus.COMPLETE
                    ? 'bg-blue-100 text-blue-800'
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {story.status.charAt(0).toUpperCase() + story.status.slice(1)}
                </span>
                {story.aiEnhanced && (
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                    AI Enhanced
                  </span>
                )}
              </div>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => handlePreview(previewData || {
              title: story?.title || '',
              situation: story?.situation || '',
              task: story?.task || '',
              action: story?.action || '',
              result: story?.result || '',
              tags: story?.tags || [],
              impactMetrics: story?.impactMetrics || {},
            })}
            className="flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
          >
            <Eye size={16} />
            Preview
          </button>
        </div>
      </div>

      {/* Story Form */}
      <StoryForm
        onSubmit={handleSubmit}
        initialData={story}
        isLoading={isLoading}
        mode={isEditing ? 'edit' : 'create'}
      />
    </div>
  )
}

interface StoryPreviewProps {
  data: StoryCreateRequest
  onBack: () => void
  onEdit: () => void
}

function StoryPreview({ data, onBack, onEdit }: StoryPreviewProps) {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Story Preview</h1>
            <p className="text-gray-600">Review your story before saving</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={onEdit}
            className="flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors"
          >
            <EyeOff size={16} />
            Edit
          </button>
        </div>
      </div>

      {/* Preview Content */}
      <div className="bg-white border border-gray-200 rounded-lg p-8 space-y-8">
        {/* Title */}
        <div>
          <h2 className="text-3xl font-bold text-gray-900 mb-2">{data.title}</h2>
          {data.tags.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {data.tags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex items-center px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
                >
                  {tag}
                </span>
              ))}
            </div>
          )}
        </div>

        {/* STAR Content */}
        <div className="space-y-6">
          <div>
            <h3 className="text-xl font-semibold text-gray-900 mb-3 flex items-center gap-2">
              <span className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
                S
              </span>
              Situation
            </h3>
            <div className="prose prose-gray max-w-none">
              <p className="whitespace-pre-wrap">{data.situation}</p>
            </div>
          </div>

          <div>
            <h3 className="text-xl font-semibold text-gray-900 mb-3 flex items-center gap-2">
              <span className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
                T
              </span>
              Task
            </h3>
            <div className="prose prose-gray max-w-none">
              <p className="whitespace-pre-wrap">{data.task}</p>
            </div>
          </div>

          <div>
            <h3 className="text-xl font-semibold text-gray-900 mb-3 flex items-center gap-2">
              <span className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
                A
              </span>
              Action
            </h3>
            <div className="prose prose-gray max-w-none">
              <p className="whitespace-pre-wrap">{data.action}</p>
            </div>
          </div>

          <div>
            <h3 className="text-xl font-semibold text-gray-900 mb-3 flex items-center gap-2">
              <span className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
                R
              </span>
              Result
            </h3>
            <div className="prose prose-gray max-w-none">
              <p className="whitespace-pre-wrap">{data.result}</p>
            </div>
          </div>
        </div>

        {/* Impact Metrics */}
        {data.impactMetrics && Object.keys(data.impactMetrics).length > 0 && (
          <div>
            <h3 className="text-xl font-semibold text-gray-900 mb-3">Impact Metrics</h3>
            <div className="bg-gray-50 rounded-lg p-4">
              <pre className="text-sm text-gray-700 whitespace-pre-wrap">
                {JSON.stringify(data.impactMetrics, null, 2)}
              </pre>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}