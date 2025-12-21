import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { StoryCreateRequest, StoryStatus } from '@/types'
import { useStoryTags, useEnhanceStory } from '@/hooks/useStories'
import { X, Sparkles, AlertCircle, CheckCircle } from 'lucide-react'
import toast from 'react-hot-toast'

const storySchema = z.object({
  title: z.string().min(1, 'Title is required').max(500, 'Title must be less than 500 characters'),
  situation: z.string().min(1, 'Situation is required'),
  task: z.string().min(1, 'Task is required'),
  action: z.string().min(1, 'Action is required'),
  result: z.string().min(1, 'Result is required'),
  impactMetrics: z.record(z.any()).optional(),
  tags: z.array(z.string()).default([]),
})

type StoryFormData = z.infer<typeof storySchema>

interface StoryFormProps {
  onSubmit: (data: StoryCreateRequest) => Promise<void>
  initialData?: Partial<StoryFormData> & { id?: string; status?: StoryStatus; aiEnhanced?: boolean }
  isLoading?: boolean
  mode?: 'create' | 'edit'
}

const STAR_SECTIONS = [
  {
    key: 'situation' as const,
    label: 'Situation',
    description: 'Describe the context and background of the scenario',
    placeholder: 'What was the situation or challenge you faced? Provide context about the customer, project, or environment...',
  },
  {
    key: 'task' as const,
    label: 'Task',
    description: 'Explain what needed to be accomplished',
    placeholder: 'What specific task or goal did you need to achieve? What were you responsible for?',
  },
  {
    key: 'action' as const,
    label: 'Action',
    description: 'Detail the specific actions you took',
    placeholder: 'What specific actions did you take? Focus on your personal contributions and decisions...',
  },
  {
    key: 'result' as const,
    label: 'Result',
    description: 'Quantify the outcomes and impact',
    placeholder: 'What were the measurable outcomes? Include metrics, customer feedback, or business impact...',
  },
]

export default function StoryForm({ onSubmit, initialData, isLoading, mode = 'create' }: StoryFormProps) {
  const [tagInput, setTagInput] = useState('')
  const [showTagSuggestions, setShowTagSuggestions] = useState(false)
  const [isEnhancing, setIsEnhancing] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
    getValues,
  } = useForm<StoryFormData>({
    resolver: zodResolver(storySchema),
    defaultValues: {
      title: initialData?.title || '',
      situation: initialData?.situation || '',
      task: initialData?.task || '',
      action: initialData?.action || '',
      result: initialData?.result || '',
      impactMetrics: initialData?.impactMetrics || {},
      tags: initialData?.tags || [],
    },
  })

  const tags = watch('tags')
  const formValues = watch()

  // Fetch existing tags for suggestions
  const { data: existingTags = [] } = useStoryTags()
  const enhanceStory = useEnhanceStory()

  // Filter tag suggestions based on input
  const filteredTagSuggestions = existingTags.filter(
    (tag) =>
      tag.toLowerCase().includes(tagInput.toLowerCase()) &&
      !tags.includes(tag)
  )

  // Calculate story completeness
  const completeness = STAR_SECTIONS.reduce((acc, section) => {
    const value = formValues[section.key]
    return acc + (value && value.trim().length > 0 ? 25 : 0)
  }, 0)

  const handleFormSubmit = async (data: StoryFormData) => {
    try {
      await onSubmit(data)
      if (mode === 'create') {
        reset()
        setTagInput('')
        toast.success('Story created successfully!')
      } else {
        toast.success('Story updated successfully!')
      }
    } catch (error) {
      toast.error(`Failed to ${mode === 'create' ? 'create' : 'update'} story. Please try again.`)
    }
  }

  const handleAddTag = (tag: string) => {
    if (tag && !tags.includes(tag)) {
      setValue('tags', [...tags, tag])
      setTagInput('')
      setShowTagSuggestions(false)
    }
  }

  const handleRemoveTag = (tagToRemove: string) => {
    setValue(
      'tags',
      tags.filter((tag) => tag !== tagToRemove)
    )
  }

  const handleTagInputKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      if (tagInput.trim()) {
        handleAddTag(tagInput.trim())
      }
    }
  }

  const handleEnhanceStory = async () => {
    if (!initialData?.id) {
      toast.error('Please save the story first before enhancing')
      return
    }

    try {
      setIsEnhancing(true)
      const enhancedStory = await enhanceStory.mutateAsync(initialData.id)
      
      // Update form with enhanced content
      setValue('situation', enhancedStory.situation)
      setValue('task', enhancedStory.task)
      setValue('action', enhancedStory.action)
      setValue('result', enhancedStory.result)
      setValue('impactMetrics', enhancedStory.impactMetrics)
      
      toast.success('Story enhanced with AI suggestions!')
    } catch (error) {
      toast.error('Failed to enhance story. Please try again.')
    } finally {
      setIsEnhancing(false)
    }
  }

  return (
    <div className="space-y-8">
      {/* Header with completeness indicator */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">
            {mode === 'create' ? 'Create New Story' : 'Edit Story'}
          </h2>
          <p className="text-gray-600 mt-1">
            Use the STAR format to create compelling customer success stories
          </p>
        </div>
        
        <div className="flex items-center gap-4">
          {/* Completeness indicator */}
          <div className="flex items-center gap-2">
            <div className="w-16 h-2 bg-gray-200 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-300 ${
                  completeness === 100 ? 'bg-green-500' : 'bg-blue-500'
                }`}
                style={{ width: `${completeness}%` }}
              />
            </div>
            <span className="text-sm text-gray-600">{completeness}%</span>
            {completeness === 100 && <CheckCircle size={16} className="text-green-500" />}
          </div>

          {/* AI Enhancement button */}
          {mode === 'edit' && initialData?.id && (
            <button
              type="button"
              onClick={handleEnhanceStory}
              disabled={isEnhancing || completeness < 100}
              className="flex items-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Sparkles size={16} />
              {isEnhancing ? 'Enhancing...' : 'AI Enhance'}
            </button>
          )}
        </div>
      </div>

      <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-8">
        {/* Title */}
        <div>
          <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
            Story Title *
          </label>
          <input
            id="title"
            type="text"
            {...register('title')}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            placeholder="e.g., Helped Acme Corp reduce deployment time by 80%"
          />
          {errors.title && (
            <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
          )}
        </div>

        {/* STAR Format Sections */}
        <div className="space-y-6">
          <div className="border-l-4 border-blue-500 pl-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">STAR Format</h3>
            <p className="text-gray-600 text-sm">
              Structure your story using the STAR method for maximum impact
            </p>
          </div>

          {STAR_SECTIONS.map((section, index) => (
            <div key={section.key} className="space-y-2">
              <div className="flex items-center gap-3">
                <div className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-800 rounded-full text-sm font-semibold">
                  {index + 1}
                </div>
                <div>
                  <label htmlFor={section.key} className="block text-sm font-medium text-gray-700">
                    {section.label} *
                  </label>
                  <p className="text-xs text-gray-500">{section.description}</p>
                </div>
              </div>
              
              <textarea
                id={section.key}
                {...register(section.key)}
                rows={4}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder={section.placeholder}
              />
              {errors[section.key] && (
                <p className="text-sm text-red-600 flex items-center gap-1">
                  <AlertCircle size={14} />
                  {errors[section.key]?.message}
                </p>
              )}
            </div>
          ))}
        </div>

        {/* Tags */}
        <div>
          <label htmlFor="tags" className="block text-sm font-medium text-gray-700 mb-1">
            Tags
          </label>
          <p className="text-xs text-gray-500 mb-2">
            Add tags to categorize and organize your stories
          </p>
          <div className="relative">
            <input
              id="tags"
              type="text"
              value={tagInput}
              onChange={(e) => {
                setTagInput(e.target.value)
                setShowTagSuggestions(e.target.value.length >= 1)
              }}
              onKeyDown={handleTagInputKeyDown}
              onFocus={() => setShowTagSuggestions(tagInput.length >= 1)}
              onBlur={() => setTimeout(() => setShowTagSuggestions(false), 200)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Type to add tags (press Enter)"
            />
            
            {/* Tag suggestions */}
            {showTagSuggestions && filteredTagSuggestions.length > 0 && (
              <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-40 overflow-y-auto">
                {filteredTagSuggestions.map((tag, index) => (
                  <button
                    key={index}
                    type="button"
                    onClick={() => handleAddTag(tag)}
                    className="w-full px-4 py-2 text-left hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
                  >
                    {tag}
                  </button>
                ))}
              </div>
            )}
          </div>
          
          {/* Selected tags */}
          {tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-2">
              {tags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex items-center gap-1 px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm"
                >
                  {tag}
                  <button
                    type="button"
                    onClick={() => handleRemoveTag(tag)}
                    className="hover:text-blue-900"
                  >
                    <X size={14} />
                  </button>
                </span>
              ))}
            </div>
          )}
        </div>

        {/* Story Guidance */}
        {completeness < 100 && (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex items-start gap-3">
              <AlertCircle className="text-yellow-600 mt-0.5" size={20} />
              <div>
                <h4 className="text-sm font-medium text-yellow-800 mb-1">
                  Story Incomplete
                </h4>
                <p className="text-sm text-yellow-700">
                  Complete all STAR sections to create a compelling story. Missing sections will be highlighted above.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Submit Button */}
        <div className="flex justify-end gap-4">
          <button
            type="submit"
            disabled={isLoading}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? 'Saving...' : mode === 'create' ? 'Create Story' : 'Update Story'}
          </button>
        </div>
      </form>
    </div>
  )
}