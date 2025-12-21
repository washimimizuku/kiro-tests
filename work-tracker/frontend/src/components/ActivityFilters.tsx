import { useState, useEffect } from 'react'
import { Search, Filter, X } from 'lucide-react'
import { ActivityCategory, ActivityFilters as ActivityFiltersType } from '@/types'
import { useActivityTags } from '@/hooks/useActivities'

interface ActivityFiltersProps {
  filters: ActivityFiltersType
  onFiltersChange: (filters: ActivityFiltersType) => void
}

const categoryLabels: Record<ActivityCategory, string> = {
  [ActivityCategory.CUSTOMER_ENGAGEMENT]: 'Customer Engagement',
  [ActivityCategory.LEARNING]: 'Learning',
  [ActivityCategory.SPEAKING]: 'Speaking',
  [ActivityCategory.MENTORING]: 'Mentoring',
  [ActivityCategory.TECHNICAL_CONSULTATION]: 'Technical Consultation',
  [ActivityCategory.CONTENT_CREATION]: 'Content Creation',
}

export default function ActivityFilters({ filters, onFiltersChange }: ActivityFiltersProps) {
  const [showAdvanced, setShowAdvanced] = useState(false)
  const [searchInput, setSearchInput] = useState(filters.search || '')
  
  const { data: availableTags = [] } = useActivityTags()

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      onFiltersChange({ ...filters, search: searchInput || undefined })
    }, 300)

    return () => clearTimeout(timer)
  }, [searchInput])

  const handleCategoryChange = (category: ActivityCategory) => {
    onFiltersChange({
      ...filters,
      category: filters.category === category ? undefined : category,
    })
  }

  const handleTagToggle = (tag: string) => {
    const currentTags = filters.tags || []
    const newTags = currentTags.includes(tag)
      ? currentTags.filter((t) => t !== tag)
      : [...currentTags, tag]
    
    onFiltersChange({
      ...filters,
      tags: newTags.length > 0 ? newTags : undefined,
    })
  }

  const handleDateChange = (field: 'dateFrom' | 'dateTo', value: string) => {
    onFiltersChange({
      ...filters,
      [field]: value || undefined,
    })
  }

  const handleImpactLevelChange = (level: number) => {
    onFiltersChange({
      ...filters,
      impactLevel: filters.impactLevel === level ? undefined : level,
    })
  }

  const clearFilters = () => {
    setSearchInput('')
    onFiltersChange({})
  }

  const hasActiveFilters = Object.values(filters).some(value => 
    value !== undefined && value !== '' && (Array.isArray(value) ? value.length > 0 : true)
  )

  return (
    <div className="card space-y-4">
      {/* Search Bar */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
        <input
          type="text"
          placeholder="Search activities..."
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
      </div>

      {/* Filter Toggle and Clear */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="inline-flex items-center gap-2 px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
        >
          <Filter size={16} />
          {showAdvanced ? 'Hide Filters' : 'Show Filters'}
        </button>
        
        {hasActiveFilters && (
          <button
            onClick={clearFilters}
            className="inline-flex items-center gap-1 px-3 py-1.5 text-sm text-red-600 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors"
          >
            <X size={16} />
            Clear All
          </button>
        )}
      </div>

      {/* Advanced Filters */}
      {showAdvanced && (
        <div className="space-y-4 pt-4 border-t border-gray-200">
          {/* Category Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Category
            </label>
            <div className="flex flex-wrap gap-2">
              {Object.entries(categoryLabels).map(([value, label]) => (
                <button
                  key={value}
                  onClick={() => handleCategoryChange(value as ActivityCategory)}
                  className={`px-3 py-1.5 text-sm rounded-lg border transition-colors ${
                    filters.category === value
                      ? 'bg-blue-100 border-blue-300 text-blue-800'
                      : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          {/* Date Range */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                From Date
              </label>
              <input
                type="date"
                value={filters.dateFrom || ''}
                onChange={(e) => handleDateChange('dateFrom', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                To Date
              </label>
              <input
                type="date"
                value={filters.dateTo || ''}
                onChange={(e) => handleDateChange('dateTo', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Impact Level */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Minimum Impact Level
            </label>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((level) => (
                <button
                  key={level}
                  onClick={() => handleImpactLevelChange(level)}
                  className={`w-10 h-10 text-sm rounded-lg border transition-colors ${
                    filters.impactLevel === level
                      ? 'bg-blue-100 border-blue-300 text-blue-800'
                      : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  {level}
                </button>
              ))}
            </div>
          </div>

          {/* Tags */}
          {availableTags.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Tags
              </label>
              <div className="flex flex-wrap gap-2">
                {availableTags.map((tag) => (
                  <button
                    key={tag}
                    onClick={() => handleTagToggle(tag)}
                    className={`px-3 py-1.5 text-sm rounded-lg border transition-colors ${
                      filters.tags?.includes(tag)
                        ? 'bg-blue-100 border-blue-300 text-blue-800'
                        : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    {tag}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}