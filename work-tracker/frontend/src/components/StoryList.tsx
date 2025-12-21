import { useState } from 'react'
import { format, parseISO } from 'date-fns'
import { 
  Edit2, 
  Trash2, 
  Eye, 
  Calendar, 
  Tag, 
  Sparkles, 
  Download,
  Share2,
  MoreVertical,
  FileText
} from 'lucide-react'
import { Story, StoryStatus } from '@/types'
import { useDeleteStory, useEnhanceStory } from '@/hooks/useStories'
import toast from 'react-hot-toast'

interface StoryListProps {
  stories: Story[]
  onEdit?: (story: Story) => void
  onView?: (story: Story) => void
  isLoading?: boolean
}

const statusLabels: Record<StoryStatus, string> = {
  [StoryStatus.DRAFT]: 'Draft',
  [StoryStatus.COMPLETE]: 'Complete',
  [StoryStatus.PUBLISHED]: 'Published',
}

const statusColors: Record<StoryStatus, string> = {
  [StoryStatus.DRAFT]: 'bg-gray-100 text-gray-800',
  [StoryStatus.COMPLETE]: 'bg-blue-100 text-blue-800',
  [StoryStatus.PUBLISHED]: 'bg-green-100 text-green-800',
}

export default function StoryList({ stories, onEdit, onView, isLoading }: StoryListProps) {
  const [deletingId, setDeletingId] = useState<string | null>(null)
  const [enhancingId, setEnhancingId] = useState<string | null>(null)
  const [openMenuId, setOpenMenuId] = useState<string | null>(null)

  const deleteStory = useDeleteStory()
  const enhanceStory = useEnhanceStory()

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this story? This action cannot be undone.')) {
      return
    }

    try {
      setDeletingId(id)
      await deleteStory.mutateAsync(id)
      toast.success('Story deleted successfully')
    } catch (error) {
      toast.error('Failed to delete story')
    } finally {
      setDeletingId(null)
      setOpenMenuId(null)
    }
  }

  const handleEnhance = async (story: Story) => {
    try {
      setEnhancingId(story.id)
      await enhanceStory.mutateAsync(story.id)
      toast.success('Story enhanced with AI suggestions!')
    } catch (error) {
      toast.error('Failed to enhance story')
    } finally {
      setEnhancingId(null)
      setOpenMenuId(null)
    }
  }

  const handleExport = (story: Story) => {
    // Create a formatted text version of the story
    const exportContent = `# ${story.title}

**Created:** ${format(parseISO(story.createdAt), 'MMMM d, yyyy')}
**Status:** ${statusLabels[story.status]}
**Tags:** ${story.tags.join(', ')}
${story.aiEnhanced ? '**AI Enhanced:** Yes' : ''}

## Situation
${story.situation}

## Task
${story.task}

## Action
${story.action}

## Result
${story.result}

${Object.keys(story.impactMetrics).length > 0 ? `## Impact Metrics
${JSON.stringify(story.impactMetrics, null, 2)}` : ''}
`

    // Create and download the file
    const blob = new Blob([exportContent], { type: 'text/markdown' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${story.title.replace(/[^a-z0-9]/gi, '_').toLowerCase()}.md`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    
    toast.success('Story exported successfully')
    setOpenMenuId(null)
  }

  const handleShare = async (story: Story) => {
    const shareText = `${story.title}\n\n${story.situation.substring(0, 200)}...`
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: story.title,
          text: shareText,
          url: window.location.href,
        })
      } catch (error) {
        // User cancelled sharing
      }
    } else {
      // Fallback: copy to clipboard
      try {
        await navigator.clipboard.writeText(shareText)
        toast.success('Story content copied to clipboard')
      } catch (error) {
        toast.error('Failed to copy to clipboard')
      }
    }
    setOpenMenuId(null)
  }

  const calculateCompleteness = (story: Story) => {
    const sections = [story.situation, story.task, story.action, story.result]
    const completedSections = sections.filter(section => section && section.trim().length > 0)
    return (completedSections.length / sections.length) * 100
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        {[...Array(3)].map((_, i) => (
          <div key={i} className="card animate-pulse">
            <div className="h-6 bg-gray-200 rounded w-3/4 mb-3"></div>
            <div className="h-4 bg-gray-200 rounded w-full mb-2"></div>
            <div className="h-4 bg-gray-200 rounded w-2/3 mb-4"></div>
            <div className="flex gap-2">
              <div className="h-6 bg-gray-200 rounded w-20"></div>
              <div className="h-6 bg-gray-200 rounded w-16"></div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (stories.length === 0) {
    return (
      <div className="card text-center py-12">
        <FileText className="mx-auto h-12 w-12 text-gray-400 mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">No stories found</h3>
        <p className="text-gray-500">
          Start by creating your first customer success story using the STAR format.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {stories.map((story) => {
        const completeness = calculateCompleteness(story)
        
        return (
          <div key={story.id} className="card hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-2">
                  <h3 className="text-lg font-semibold text-gray-900">{story.title}</h3>
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      statusColors[story.status]
                    }`}
                  >
                    {statusLabels[story.status]}
                  </span>
                  {story.aiEnhanced && (
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
                      <Sparkles size={12} />
                      AI Enhanced
                    </span>
                  )}
                </div>
                
                {/* Story preview */}
                <p className="text-gray-600 mb-3 line-clamp-2">
                  {story.situation.substring(0, 200)}
                  {story.situation.length > 200 && '...'}
                </p>
              </div>

              {/* Actions menu */}
              <div className="relative ml-4">
                <button
                  onClick={() => setOpenMenuId(openMenuId === story.id ? null : story.id)}
                  className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  <MoreVertical size={16} />
                </button>

                {openMenuId === story.id && (
                  <div className="absolute right-0 top-10 w-48 bg-white border border-gray-200 rounded-lg shadow-lg z-10">
                    <div className="py-1">
                      {onView && (
                        <button
                          onClick={() => {
                            onView(story)
                            setOpenMenuId(null)
                          }}
                          className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        >
                          <Eye size={16} />
                          View
                        </button>
                      )}
                      {onEdit && (
                        <button
                          onClick={() => {
                            onEdit(story)
                            setOpenMenuId(null)
                          }}
                          className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                        >
                          <Edit2 size={16} />
                          Edit
                        </button>
                      )}
                      <button
                        onClick={() => handleEnhance(story)}
                        disabled={enhancingId === story.id}
                        className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 disabled:opacity-50"
                      >
                        <Sparkles size={16} />
                        {enhancingId === story.id ? 'Enhancing...' : 'AI Enhance'}
                      </button>
                      <button
                        onClick={() => handleExport(story)}
                        className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        <Download size={16} />
                        Export
                      </button>
                      <button
                        onClick={() => handleShare(story)}
                        className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                      >
                        <Share2 size={16} />
                        Share
                      </button>
                      <hr className="my-1" />
                      <button
                        onClick={() => handleDelete(story.id)}
                        disabled={deletingId === story.id}
                        className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50 disabled:opacity-50"
                      >
                        <Trash2 size={16} />
                        {deletingId === story.id ? 'Deleting...' : 'Delete'}
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Story metadata */}
            <div className="flex flex-wrap items-center gap-4 text-sm text-gray-500">
              {/* Created date */}
              <span className="inline-flex items-center gap-1">
                <Calendar size={14} />
                {format(parseISO(story.createdAt), 'MMM d, yyyy')}
              </span>

              {/* Completeness */}
              <div className="flex items-center gap-2">
                <span>Completeness:</span>
                <div className="w-16 h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className={`h-full transition-all duration-300 ${
                      completeness === 100 ? 'bg-green-500' : 'bg-blue-500'
                    }`}
                    style={{ width: `${completeness}%` }}
                  />
                </div>
                <span className="text-xs">{completeness}%</span>
              </div>

              {/* Tags */}
              {story.tags.length > 0 && (
                <div className="flex items-center gap-1">
                  <Tag size={14} />
                  <div className="flex flex-wrap gap-1">
                    {story.tags.slice(0, 3).map((tag) => (
                      <span
                        key={tag}
                        className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-gray-100 text-gray-700"
                      >
                        {tag}
                      </span>
                    ))}
                    {story.tags.length > 3 && (
                      <span className="text-xs text-gray-500">
                        +{story.tags.length - 3} more
                      </span>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}