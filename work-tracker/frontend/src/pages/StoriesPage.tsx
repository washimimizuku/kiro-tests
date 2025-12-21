import { useState } from 'react'
import { Plus, BookOpen } from 'lucide-react'
import { Story, StoryFilters } from '@/types'
import { useStories } from '@/hooks/useStories'
import StoryList from '@/components/StoryList'
import StoryFilters from '@/components/StoryFilters'
import StoryEditor from '@/components/StoryEditor'

type ViewMode = 'list' | 'create' | 'edit' | 'view'

export default function StoriesPage() {
  const [viewMode, setViewMode] = useState<ViewMode>('list')
  const [selectedStory, setSelectedStory] = useState<Story | null>(null)
  const [filters, setFilters] = useState<StoryFilters>({})
  const [currentPage, setCurrentPage] = useState(1)

  const { data: storiesResponse, isLoading } = useStories(filters, currentPage, 20)
  const stories = storiesResponse?.data || []
  const totalCount = storiesResponse?.total || 0

  const handleCreateNew = () => {
    setSelectedStory(null)
    setViewMode('create')
  }

  const handleEdit = (story: Story) => {
    setSelectedStory(story)
    setViewMode('edit')
  }

  const handleView = (story: Story) => {
    setSelectedStory(story)
    setViewMode('view')
  }

  const handleBack = () => {
    setSelectedStory(null)
    setViewMode('list')
  }

  const handleSave = (story: Story) => {
    setSelectedStory(story)
    setViewMode('list')
  }

  const handleFiltersChange = (newFilters: StoryFilters) => {
    setFilters(newFilters)
    setCurrentPage(1) // Reset to first page when filters change
  }

  if (viewMode === 'create') {
    return (
      <StoryEditor
        onBack={handleBack}
        onSave={handleSave}
      />
    )
  }

  if (viewMode === 'edit' && selectedStory) {
    return (
      <StoryEditor
        storyId={selectedStory.id}
        onBack={handleBack}
        onSave={handleSave}
      />
    )
  }

  if (viewMode === 'view' && selectedStory) {
    return (
      <StoryViewer
        story={selectedStory}
        onBack={handleBack}
        onEdit={() => handleEdit(selectedStory)}
      />
    )
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Stories</h1>
          <p className="mt-2 text-gray-600">
            Create and manage customer success stories using the STAR format
          </p>
        </div>
        <button
          onClick={handleCreateNew}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          <Plus size={20} />
          New Story
        </button>
      </div>

      {/* Filters */}
      <StoryFilters
        filters={filters}
        onFiltersChange={handleFiltersChange}
        totalCount={totalCount}
        filteredCount={stories.length}
      />

      {/* Stories List */}
      <StoryList
        stories={stories}
        onEdit={handleEdit}
        onView={handleView}
        isLoading={isLoading}
      />

      {/* Pagination */}
      {storiesResponse && storiesResponse.totalPages > 1 && (
        <div className="flex items-center justify-center gap-2">
          <button
            onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
            disabled={currentPage === 1}
            className="px-3 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          
          <div className="flex items-center gap-1">
            {Array.from({ length: Math.min(5, storiesResponse.totalPages) }, (_, i) => {
              const page = i + 1
              return (
                <button
                  key={page}
                  onClick={() => setCurrentPage(page)}
                  className={`px-3 py-2 text-sm rounded-lg ${
                    currentPage === page
                      ? 'bg-blue-600 text-white'
                      : 'text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  {page}
                </button>
              )
            })}
          </div>
          
          <button
            onClick={() => setCurrentPage(Math.min(storiesResponse.totalPages, currentPage + 1))}
            disabled={currentPage === storiesResponse.totalPages}
            className="px-3 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}
    </div>
  )
}

interface StoryViewerProps {
  story: Story
  onBack: () => void
  onEdit: () => void
}

function StoryViewer({ story, onBack, onEdit }: StoryViewerProps) {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <BookOpen size={20} />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Story Details</h1>
            <p className="text-gray-600">View customer success story</p>
          </div>
        </div>

        <button
          onClick={onEdit}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          Edit Story
        </button>
      </div>

      {/* Story Content */}
      <div className="bg-white border border-gray-200 rounded-lg p-8 space-y-8">
        {/* Title and metadata */}
        <div>
          <h2 className="text-3xl font-bold text-gray-900 mb-4">{story.title}</h2>
          <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
            <span>Created: {new Date(story.createdAt).toLocaleDateString()}</span>
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
              story.status === 'published'
                ? 'bg-green-100 text-green-800'
                : story.status === 'complete'
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
          
          {story.tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3">
              {story.tags.map((tag) => (
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
              <p className="whitespace-pre-wrap">{story.situation}</p>
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
              <p className="whitespace-pre-wrap">{story.task}</p>
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
              <p className="whitespace-pre-wrap">{story.action}</p>
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
              <p className="whitespace-pre-wrap">{story.result}</p>
            </div>
          </div>
        </div>

        {/* Impact Metrics */}
        {story.impactMetrics && Object.keys(story.impactMetrics).length > 0 && (
          <div>
            <h3 className="text-xl font-semibold text-gray-900 mb-3">Impact Metrics</h3>
            <div className="bg-gray-50 rounded-lg p-4">
              <pre className="text-sm text-gray-700 whitespace-pre-wrap">
                {JSON.stringify(story.impactMetrics, null, 2)}
              </pre>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}