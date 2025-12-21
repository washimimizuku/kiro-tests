import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { ActivityCategory, ActivityCreateRequest } from '@/types'
import { useActivitySuggestions, useActivityTags } from '@/hooks/useActivities'
import { X } from 'lucide-react'
import toast from 'react-hot-toast'

const activitySchema = z.object({
  title: z.string().min(1, 'Title is required').max(500, 'Title must be less than 500 characters'),
  description: z.string().optional(),
  category: z.nativeEnum(ActivityCategory, { required_error: 'Category is required' }),
  tags: z.array(z.string()).default([]),
  impactLevel: z.number().min(1).max(5),
  date: z.string().min(1, 'Date is required'),
  durationMinutes: z.number().optional(),
})

type ActivityFormData = z.infer<typeof activitySchema>

interface ActivityFormProps {
  onSubmit: (data: ActivityCreateRequest) => Promise<void>
  initialData?: Partial<ActivityFormData>
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

export default function ActivityForm({ onSubmit, initialData, isLoading }: ActivityFormProps) {
  const [titleInput, setTitleInput] = useState('')
  const [showSuggestions, setShowSuggestions] = useState(false)
  const [tagInput, setTagInput] = useState('')
  const [showTagSuggestions, setShowTagSuggestions] = useState(false)

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    setValue,
    watch,
  } = useForm<ActivityFormData>({
    resolver: zodResolver(activitySchema),
    defaultValues: {
      title: initialData?.title || '',
      description: initialData?.description || '',
      category: initialData?.category || ActivityCategory.CUSTOMER_ENGAGEMENT,
      tags: initialData?.tags || [],
      impactLevel: initialData?.impactLevel || 3,
      date: initialData?.date || new Date().toISOString().split('T')[0],
      durationMinutes: initialData?.durationMinutes,
    },
  })

  const tags = watch('tags')
  const title = watch('title')

  // Fetch suggestions for title auto-complete
  const { data: suggestions = [] } = useActivitySuggestions(titleInput)
  
  // Fetch existing tags for suggestions
  const { data: existingTags = [] } = useActivityTags()

  // Filter tag suggestions based on input
  const filteredTagSuggestions = existingTags.filter(
    (tag) =>
      tag.toLowerCase().includes(tagInput.toLowerCase()) &&
      !tags.includes(tag)
  )

  useEffect(() => {
    setTitleInput(title)
  }, [title])

  const handleFormSubmit = async (data: ActivityFormData) => {
    try {
      await onSubmit(data)
      reset()
      setTitleInput('')
      setTagInput('')
      toast.success('Activity logged successfully!')
    } catch (error) {
      toast.error('Failed to log activity. Please try again.')
    }
  }

  const handleSuggestionClick = (suggestion: string) => {
    setValue('title', suggestion)
    setTitleInput(suggestion)
    setShowSuggestions(false)
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

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
      {/* Title with Auto-complete */}
      <div className="relative">
        <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
          Activity Title *
        </label>
        <input
          id="title"
          type="text"
          {...register('title')}
          onChange={(e) => {
            setValue('title', e.target.value)
            setTitleInput(e.target.value)
            setShowSuggestions(e.target.value.length >= 2)
          }}
          onFocus={() => setShowSuggestions(titleInput.length >= 2)}
          onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          placeholder="e.g., Customer meeting with Acme Corp"
        />
        {errors.title && (
          <p className="mt-1 text-sm text-red-600">{errors.title.message}</p>
        )}
        
        {/* Auto-complete suggestions */}
        {showSuggestions && suggestions.length > 0 && (
          <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto">
            {suggestions.map((suggestion, index) => (
              <button
                key={index}
                type="button"
                onClick={() => handleSuggestionClick(suggestion)}
                className="w-full px-4 py-2 text-left hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
              >
                {suggestion}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Description */}
      <div>
        <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
          Description
        </label>
        <textarea
          id="description"
          {...register('description')}
          rows={3}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          placeholder="Provide additional details about this activity..."
        />
        {errors.description && (
          <p className="mt-1 text-sm text-red-600">{errors.description.message}</p>
        )}
      </div>

      {/* Category Selection */}
      <div>
        <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-1">
          Category *
        </label>
        <select
          id="category"
          {...register('category')}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          {Object.entries(categoryLabels).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        {errors.category && (
          <p className="mt-1 text-sm text-red-600">{errors.category.message}</p>
        )}
      </div>

      {/* Tags */}
      <div>
        <label htmlFor="tags" className="block text-sm font-medium text-gray-700 mb-1">
          Tags
        </label>
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

      {/* Date and Duration */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label htmlFor="date" className="block text-sm font-medium text-gray-700 mb-1">
            Date *
          </label>
          <input
            id="date"
            type="date"
            {...register('date')}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          {errors.date && (
            <p className="mt-1 text-sm text-red-600">{errors.date.message}</p>
          )}
        </div>

        <div>
          <label htmlFor="durationMinutes" className="block text-sm font-medium text-gray-700 mb-1">
            Duration (minutes)
          </label>
          <input
            id="durationMinutes"
            type="number"
            {...register('durationMinutes', { valueAsNumber: true })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            placeholder="e.g., 60"
          />
          {errors.durationMinutes && (
            <p className="mt-1 text-sm text-red-600">{errors.durationMinutes.message}</p>
          )}
        </div>
      </div>

      {/* Impact Level */}
      <div>
        <label htmlFor="impactLevel" className="block text-sm font-medium text-gray-700 mb-1">
          Impact Level * (1-5)
        </label>
        <div className="flex items-center gap-4">
          <input
            id="impactLevel"
            type="range"
            min="1"
            max="5"
            {...register('impactLevel', { valueAsNumber: true })}
            className="flex-1"
          />
          <span className="text-lg font-semibold text-gray-700 w-8 text-center">
            {watch('impactLevel')}
          </span>
        </div>
        <div className="flex justify-between text-xs text-gray-500 mt-1">
          <span>Low</span>
          <span>High</span>
        </div>
        {errors.impactLevel && (
          <p className="mt-1 text-sm text-red-600">{errors.impactLevel.message}</p>
        )}
      </div>

      {/* Submit Button */}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={isLoading}
          className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? 'Saving...' : 'Log Activity'}
        </button>
      </div>
    </form>
  )
}
