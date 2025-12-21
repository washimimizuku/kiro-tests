import { useState, useEffect } from 'react'
import { Search, Filter, X, Sparkles, FileText } from 'lucide-react'
import { StoryFilters as StoryFiltersType, StoryStatus } from '@/types'
import { useStoryTags } from '@/hooks/useStories'

interface StoryFiltersProps {
  filters: StoryFiltersType
  onFiltersChange: (filters: StoryFiltersType) => void
  totalCount?: number
  filteredCount?: number
}

const statusOptions = [
  { value: StoryStatus.DRAFT, label: 'Draft', color: 'bg-gray-100 text-gray-800' },
  { value: StoryStatus.COMPLETE, label: 'Complete', color: 'bg-blue-100 text-blue-800' },
  { value: StoryStatus.PUBLISHED, label: 'Published', color: 'bg-green-100 text-green-800' },
]

export default function StoryFilters({ 
  filters, 
  onFiltersChange, 
  totalCount = 0, 
  filteredCount = 0 
}: StoryFiltersProps) {
  const [searchInput, setSearchInput] = useState(filters.search || '')
  const [showAdvancedFilters, setShowAdvancedFilters] = useState(false)
  const [tagInput, setTagInput] = useState('')
  const [showTagSuggestions, setShowTagSuggestions] = useState(false)

  const { data: availableTags = [] } = useStoryTags()

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      onFiltersChange({ ...filters, search: searchInput || undefined })
    }, 300)

    return () => clearTimeout(timer)
  }, [searchInput])

  const handleStatusChange = (status: StoryStatus) => {
    onFiltersChange({
      ...filters,
      status: filters.status === status ? undefined : status,
    })
  }

  const handleAiEnhancedChange = (aiEnhanced: boolean | undefined) => {
    onFiltersChange({
      ...filters,
      aiEnhanced,
    })
  }

  const handleAddTag = (tag: string) => {
    if (tag && !filters.tags?.includes(tag)) {
      onFiltersChange({
        ...filters,
        tags: [...(filters.tags || []), tag],
      })
      setTagInput('')
      setShowTagSuggestions(false)
    }
  }

  const handleRemoveTag = (tagToRemove: string) => {
    onFiltersChange({
      ...filters,
      tags: filters.tags?.filter(tag => tag !== tagToRemove),
    })
  }

  const handleTagInputKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      if (tagInput.trim()) {
        handleAddTag(tagInput.trim())
      }
    }
  }

  const clearAllFilters = () => {
    setSearchInput('')
    setTagInput('')
    onFiltersChange({})
  }

  const hasActiveFilters = !!(
    filters.search ||
    filters.status ||
    filters.aiEnhanced !== undefined ||
    (filters.tags && filters.tags.length > 0)
  )

  const filteredTagSuggestions = availableTags.filter(
    (tag) =>
      tag.toLowerCase().includes(tagInput.toLowerCase()) &&
      !filters.tags?.includes(tag)
  )

  return (
    <div className="space-y-4">
      {/* Search and basic filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        {/* Search input */}
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
          <input
            type="text"
            placeholder="Search stories by title or content..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        {/* Advanced filters toggle */}
        <button
          onClick={() => setShowAdvancedFilters(!showAdvancedFilters)}
          className={`flex items-center gap-2 px-4 py-2 border rounded-lg transition-colors ${
            showAdvancedFilters || hasActiveFilters
              ? 'border-blue-500 bg-blue-50 text-blue-700'
              : 'border-gray-300 text-gray-700 hover:bg-gray-50'
          }`}
        >
          <Filter size={16} />
          Filters
          {hasActiveFilters && (
            <span className="bg-blue-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
              {[
                filters.status,
                filters.aiEnhanced !== undefined,
                filters.tags?.length || 0,
              ].filter(Boolean).length}
            </span>
          )}
        </button>

        {/* Clear filters */}
        {hasActiveFilters && (
          <button
            onClick={clearAllFilters}
            className="flex items-center gap-2 px-4 py-2 text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X size={16} />
            Clear
          </button>
        )}
      </div>

      {/* Results count */}
      {totalCount > 0 && (
        <div className="text-sm text-gray-600">
          {hasActiveFilters ? (
            <>
              Showing {filteredCount} of {totalCount} stories
              {filteredCount !== totalCount && (
                <span className="text-blue-600 ml-1">
                  ({totalCount - filteredCount} filtered out)
                </span>
              )}
            </>
          ) : (
            `${totalCount} ${totalCount === 1 ? 'story' : 'stories'} total`
          )}
        </div>
      )}

      {/* Advanced filters */}
      {showAdvancedFilters && (
        <div className="border border-gray-200 rounded-lg p-4 space-y-4 bg-gray-50">
          {/* Status filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Status
            </label>
            <div className="flex flex-wrap gap-2">
              {statusOptions.map((option) => (
                <button
                  key={option.value}
                  onClick={() => handleStatusChange(option.value)}
                  className={`inline-flex items-center px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                    filters.status === option.value
                      ? option.color + ' ring-2 ring-blue-500'
                      : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                  }`}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>

          {/* AI Enhanced filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              AI Enhancement
            </label>
            <div className="flex gap-2">
              <button
                onClick={() => handleAiEnhancedChange(true)}
                className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                  filters.aiEnhanced === true
                    ? 'bg-purple-100 text-purple-800 ring-2 ring-purple-500'
                    : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                }`}
              >
                <Sparkles size={14} />
                AI Enhanced
              </button>
              <button
                onClick={() => handleAiEnhancedChange(false)}
                className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                  filters.aiEnhanced === false
                    ? 'bg-gray-100 text-gray-800 ring-2 ring-gray-500'
                    : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
                }`}
              >
                <FileText size={14} />
                Manual Only
              </button>
            </div>
          </div>

          {/* Tags filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tags
            </label>
            <div className="relative">
              <input
                type="text"
                placeholder="Type to add tag filters..."
                value={tagInput}
                onChange={(e) => {
                  setTagInput(e.target.value)
                  setShowTagSuggestions(e.target.value.length >= 1)
                }}
                onKeyDown={handleTagInputKeyDown}
                onFocus={() => setShowTagSuggestions(tagInput.length >= 1)}
                onBlur={() => setTimeout(() => setShowTagSuggestions(false), 200)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
              
              {/* Tag suggestions */}
              {showTagSuggestions && filteredTagSuggestions.length > 0 && (
                <div className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-40 overflow-y-auto">
                  {filteredTagSuggestions.map((tag, index) => (
                    <button
                      key={index}
                      type="button"
                      onClick={() => handleAddTag(tag)}
                      className="w-full px-3 py-2 text-left hover:bg-gray-100 focus:bg-gray-100 focus:outline-none"
                    >
                      {tag}
                    </button>
                  ))}
                </div>
              )}
            </div>
            
            {/* Selected tags */}
            {filters.tags && filters.tags.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-2">
                {filters.tags.map((tag) => (
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
        </div>
      )}
    </div>
  )
}