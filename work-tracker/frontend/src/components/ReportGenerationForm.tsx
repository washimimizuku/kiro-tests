import React, { useState } from 'react'
import { useForm } from 'react-hook-form'
import { ReportGenerateRequest, ReportType, ActivityCategory } from '@/types'
import { useActivities } from '@/hooks/useActivities'
import { useStories } from '@/hooks/useStories'

interface ReportGenerationFormProps {
  onSubmit: (data: ReportGenerateRequest) => void
  isLoading?: boolean
}

interface FormData {
  title: string
  periodStart: string
  periodEnd: string
  reportType: ReportType
  includeCategories: ActivityCategory[]
  includeTags: string[]
  includeStories: string[]
}

export default function ReportGenerationForm({ onSubmit, isLoading = false }: ReportGenerationFormProps) {
  const [selectedCategories, setSelectedCategories] = useState<ActivityCategory[]>([])
  const [selectedTags, setSelectedTags] = useState<string[]>([])
  const [selectedStories, setSelectedStories] = useState<string[]>([])
  
  const { register, handleSubmit, watch, setValue, formState: { errors } } = useForm<FormData>({
    defaultValues: {
      reportType: ReportType.MONTHLY,
      includeCategories: [],
      includeTags: [],
      includeStories: []
    }
  })

  const reportType = watch('reportType')
  const periodStart = watch('periodStart')
  const periodEnd = watch('periodEnd')

  // Fetch activities and stories for the selected period
  const { data: activitiesData } = useActivities({
    dateFrom: periodStart,
    dateTo: periodEnd
  }, 1, 100)
  
  const { data: storiesData } = useStories({}, 1, 100)

  // Get unique tags from activities
  const availableTags = React.useMemo(() => {
    if (!activitiesData?.data) return []
    const tags = new Set<string>()
    activitiesData.data.forEach(activity => {
      activity.tags.forEach(tag => tags.add(tag))
    })
    return Array.from(tags).sort()
  }, [activitiesData])

  const handleFormSubmit = (data: FormData) => {
    // Filter activities based on selected criteria
    const filteredActivities = activitiesData?.data?.filter(activity => {
      const categoryMatch = selectedCategories.length === 0 || selectedCategories.includes(activity.category)
      const tagMatch = selectedTags.length === 0 || selectedTags.some(tag => activity.tags.includes(tag))
      return categoryMatch && tagMatch
    }) || []

    const reportRequest: ReportGenerateRequest = {
      title: data.title,
      periodStart: data.periodStart,
      periodEnd: data.periodEnd,
      reportType: data.reportType,
      includeActivities: filteredActivities.map(a => a.id),
      includeStories: selectedStories
    }

    onSubmit(reportRequest)
  }

  const handleCategoryToggle = (category: ActivityCategory) => {
    const updated = selectedCategories.includes(category)
      ? selectedCategories.filter(c => c !== category)
      : [...selectedCategories, category]
    setSelectedCategories(updated)
    setValue('includeCategories', updated)
  }

  const handleTagToggle = (tag: string) => {
    const updated = selectedTags.includes(tag)
      ? selectedTags.filter(t => t !== tag)
      : [...selectedTags, tag]
    setSelectedTags(updated)
    setValue('includeTags', updated)
  }

  const handleStoryToggle = (storyId: string) => {
    const updated = selectedStories.includes(storyId)
      ? selectedStories.filter(s => s !== storyId)
      : [...selectedStories, storyId]
    setSelectedStories(updated)
    setValue('includeStories', updated)
  }

  // Auto-generate title based on report type and period
  React.useEffect(() => {
    if (periodStart && periodEnd && reportType) {
      const startDate = new Date(periodStart)
      const endDate = new Date(periodEnd)
      const startStr = startDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
      const endStr = endDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })
      
      let title = ''
      switch (reportType) {
        case ReportType.WEEKLY:
          title = `Weekly Report - ${startStr}`
          break
        case ReportType.MONTHLY:
          title = `Monthly Report - ${startStr}`
          break
        case ReportType.QUARTERLY:
          title = `Quarterly Report - ${startStr} to ${endStr}`
          break
        case ReportType.ANNUAL:
          title = `Annual Report - ${startDate.getFullYear()}`
          break
        case ReportType.CUSTOM:
          title = `Custom Report - ${startStr} to ${endStr}`
          break
      }
      setValue('title', title)
    }
  }, [periodStart, periodEnd, reportType, setValue])

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
      {/* Basic Information */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Report Configuration</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
              Report Title
            </label>
            <input
              {...register('title', { required: 'Title is required' })}
              type="text"
              className="input"
              placeholder="Enter report title"
            />
            {errors.title && (
              <p className="text-red-600 text-sm mt-1">{errors.title.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="reportType" className="block text-sm font-medium text-gray-700 mb-1">
              Report Type
            </label>
            <select {...register('reportType')} className="input">
              <option value={ReportType.WEEKLY}>Weekly</option>
              <option value={ReportType.MONTHLY}>Monthly</option>
              <option value={ReportType.QUARTERLY}>Quarterly</option>
              <option value={ReportType.ANNUAL}>Annual</option>
              <option value={ReportType.CUSTOM}>Custom Period</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
          <div>
            <label htmlFor="periodStart" className="block text-sm font-medium text-gray-700 mb-1">
              Start Date
            </label>
            <input
              {...register('periodStart', { required: 'Start date is required' })}
              type="date"
              className="input"
            />
            {errors.periodStart && (
              <p className="text-red-600 text-sm mt-1">{errors.periodStart.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="periodEnd" className="block text-sm font-medium text-gray-700 mb-1">
              End Date
            </label>
            <input
              {...register('periodEnd', { required: 'End date is required' })}
              type="date"
              className="input"
            />
            {errors.periodEnd && (
              <p className="text-red-600 text-sm mt-1">{errors.periodEnd.message}</p>
            )}
          </div>
        </div>
      </div>

      {/* Activity Filters */}
      <div className="card">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Activity Filters</h3>
        
        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Categories to Include
          </label>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
            {Object.values(ActivityCategory).map((category) => (
              <label key={category} className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={selectedCategories.includes(category)}
                  onChange={() => handleCategoryToggle(category)}
                  className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span className="text-sm text-gray-700 capitalize">
                  {category.replace('_', ' ')}
                </span>
              </label>
            ))}
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Leave empty to include all categories
          </p>
        </div>

        {availableTags.length > 0 && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tags to Include
            </label>
            <div className="flex flex-wrap gap-2">
              {availableTags.map((tag) => (
                <label key={tag} className="flex items-center space-x-1">
                  <input
                    type="checkbox"
                    checked={selectedTags.includes(tag)}
                    onChange={() => handleTagToggle(tag)}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700 bg-gray-100 px-2 py-1 rounded">
                    {tag}
                  </span>
                </label>
              ))}
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Leave empty to include all tags
            </p>
          </div>
        )}
      </div>

      {/* Story Selection */}
      {storiesData?.data && storiesData.data.length > 0 && (
        <div className="card">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Stories to Include</h3>
          <div className="space-y-2 max-h-48 overflow-y-auto">
            {storiesData.data.map((story) => (
              <label key={story.id} className="flex items-start space-x-2">
                <input
                  type="checkbox"
                  checked={selectedStories.includes(story.id)}
                  onChange={() => handleStoryToggle(story.id)}
                  className="mt-1 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <div className="flex-1">
                  <span className="text-sm font-medium text-gray-900">{story.title}</span>
                  <p className="text-xs text-gray-500 truncate">{story.situation}</p>
                </div>
              </label>
            ))}
          </div>
          <p className="text-xs text-gray-500 mt-2">
            Select specific stories to highlight in your report
          </p>
        </div>
      )}

      {/* Submit Button */}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={isLoading}
          className="btn btn-primary"
        >
          {isLoading ? (
            <>
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generating Report...
            </>
          ) : (
            'Generate Report'
          )}
        </button>
      </div>
    </form>
  )
}