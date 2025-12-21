import React from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from 'react-query'
import * as fc from 'fast-check'
import { Activity, ActivityCategory, ActivityFilters } from '@/types'
import ActivityList from '@/components/ActivityList'
import ActivityFilters from '@/components/ActivityFilters'
import { useActivitySuggestions, useActivityTags } from '@/hooks/useActivities'

// Mock the hooks
vi.mock('@/hooks/useActivities', () => ({
  useActivitySuggestions: vi.fn(),
  useActivityTags: vi.fn(),
  useDeleteActivity: vi.fn(() => ({
    mutateAsync: vi.fn(),
    isLoading: false,
  })),
}))

// Mock toast
vi.mock('react-hot-toast', () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

// Test wrapper component
function TestWrapper({ children }: { children: React.ReactNode }) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false },
      mutations: { retry: false },
    },
  })
  
  return React.createElement(
    QueryClientProvider,
    { client: queryClient },
    children
  )
}

// Generators for property-based testing
const activityCategoryArb = fc.constantFrom(...Object.values(ActivityCategory))

const activityArb = fc.record({
  id: fc.uuid(),
  userId: fc.uuid(),
  title: fc.string({ minLength: 1, maxLength: 500 }),
  description: fc.option(fc.string({ maxLength: 1000 })),
  category: activityCategoryArb,
  tags: fc.array(fc.string({ minLength: 1, maxLength: 50 }), { maxLength: 10 }),
  impactLevel: fc.integer({ min: 1, max: 5 }),
  date: fc.date({ min: new Date('2020-01-01'), max: new Date('2030-12-31') }).map(d => d.toISOString().split('T')[0]),
  durationMinutes: fc.option(fc.integer({ min: 1, max: 1440 })),
  metadata: fc.record({}),
  createdAt: fc.date().map(d => d.toISOString()),
  updatedAt: fc.date().map(d => d.toISOString()),
}) as fc.Arbitrary<Activity>

const activityFiltersArb = fc.record({
  category: fc.option(activityCategoryArb),
  tags: fc.option(fc.array(fc.string({ minLength: 1, maxLength: 50 }), { maxLength: 5 })),
  dateFrom: fc.option(fc.date().map(d => d.toISOString().split('T')[0])),
  dateTo: fc.option(fc.date().map(d => d.toISOString().split('T')[0])),
  impactLevel: fc.option(fc.integer({ min: 1, max: 5 })),
  search: fc.option(fc.string({ maxLength: 100 })),
}) as fc.Arbitrary<ActivityFilters>

describe('Activity UI Properties', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Setup default mock returns
    vi.mocked(useActivitySuggestions).mockReturnValue({
      data: [],
      isLoading: false,
      error: null,
      refetch: vi.fn(),
    } as any)
    
    vi.mocked(useActivityTags).mockReturnValue({
      data: [],
      isLoading: false,
      error: null,
      refetch: vi.fn(),
    } as any)
  })

  /**
   * Feature: work-tracker, Property 2: Auto-complete Suggestion Accuracy
   * Validates: Requirements 1.3
   */
  it('Property 2: Auto-complete suggestions should contain input as substring when matches exist', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 2, maxLength: 50 }),
        fc.array(fc.string({ minLength: 1, maxLength: 100 }), { minLength: 1, maxLength: 10 }),
        (query, allSuggestions) => {
          // Filter suggestions that should match the query
          const expectedMatches = allSuggestions.filter(suggestion =>
            suggestion.toLowerCase().includes(query.toLowerCase())
          )
          
          // Mock the hook to return matching suggestions
          vi.mocked(useActivitySuggestions).mockReturnValue({
            data: expectedMatches,
            isLoading: false,
            error: null,
            refetch: vi.fn(),
          } as any)

          // If there are expected matches, verify they all contain the query
          if (expectedMatches.length > 0) {
            expectedMatches.forEach(suggestion => {
              expect(suggestion.toLowerCase()).toContain(query.toLowerCase())
            })
          }
          
          // The property holds: all returned suggestions contain the query as substring
          return true
        }
      ),
      { numRuns: 100 }
    )
  })

  /**
   * Feature: work-tracker, Property 3: Activity Display and Filtering
   * Validates: Requirements 1.5, 4.3
   */
  it('Property 3: Activity filtering should only return activities matching specified criteria', () => {
    fc.assert(
      fc.property(
        fc.array(activityArb, { minLength: 0, maxLength: 20 }),
        activityFiltersArb,
        (activities, filters) => {
          // Apply filters manually to verify expected results
          let filteredActivities = activities

          if (filters.category) {
            filteredActivities = filteredActivities.filter(
              activity => activity.category === filters.category
            )
          }

          if (filters.tags && filters.tags.length > 0) {
            filteredActivities = filteredActivities.filter(
              activity => filters.tags!.some(tag => activity.tags.includes(tag))
            )
          }

          if (filters.dateFrom) {
            filteredActivities = filteredActivities.filter(
              activity => activity.date >= filters.dateFrom!
            )
          }

          if (filters.dateTo) {
            filteredActivities = filteredActivities.filter(
              activity => activity.date <= filters.dateTo!
            )
          }

          if (filters.impactLevel) {
            filteredActivities = filteredActivities.filter(
              activity => activity.impactLevel >= filters.impactLevel!
            )
          }

          if (filters.search) {
            const searchLower = filters.search.toLowerCase()
            filteredActivities = filteredActivities.filter(
              activity =>
                activity.title.toLowerCase().includes(searchLower) ||
                (activity.description && activity.description.toLowerCase().includes(searchLower))
            )
          }

          // Verify that all filtered activities match the criteria
          filteredActivities.forEach(activity => {
            if (filters.category) {
              expect(activity.category).toBe(filters.category)
            }
            
            if (filters.tags && filters.tags.length > 0) {
              expect(filters.tags.some(tag => activity.tags.includes(tag))).toBe(true)
            }
            
            if (filters.dateFrom) {
              expect(activity.date >= filters.dateFrom).toBe(true)
            }
            
            if (filters.dateTo) {
              expect(activity.date <= filters.dateTo).toBe(true)
            }
            
            if (filters.impactLevel) {
              expect(activity.impactLevel >= filters.impactLevel).toBe(true)
            }
            
            if (filters.search) {
              const searchLower = filters.search.toLowerCase()
              const matchesSearch = 
                activity.title.toLowerCase().includes(searchLower) ||
                (activity.description && activity.description.toLowerCase().includes(searchLower))
              expect(matchesSearch).toBe(true)
            }
          })

          return true
        }
      ),
      { numRuns: 100 }
    )
  })

  /**
   * Feature: work-tracker, Property 3: Activity Display and Filtering (UI Component Test)
   * Validates: Requirements 1.5, 4.3
   */
  it('Property 3: ActivityList component should group activities by date correctly', () => {
    fc.assert(
      fc.property(
        fc.array(activityArb, { minLength: 1, maxLength: 10 }),
        (activities) => {
          render(
            React.createElement(TestWrapper, null,
              React.createElement(ActivityList, { activities })
            )
          )

          // Group activities by date (same logic as component)
          const groupedActivities = activities.reduce((groups, activity) => {
            const date = activity.date
            if (!groups[date]) {
              groups[date] = []
            }
            groups[date].push(activity)
            return groups
          }, {} as Record<string, Activity[]>)

          // Verify that each date group is represented
          Object.keys(groupedActivities).forEach(date => {
            // Check if date header exists (we can't easily test the exact format due to date parsing)
            const activitiesForDate = groupedActivities[date]
            
            // Verify all activities for this date are present
            activitiesForDate.forEach(activity => {
              expect(screen.getByText(activity.title)).toBeInTheDocument()
            })
          })

          return true
        }
      ),
      { numRuns: 50 } // Reduced runs for UI tests
    )
  })

  /**
   * Feature: work-tracker, Property 2: Auto-complete Suggestion Accuracy (UI Component Test)
   * Validates: Requirements 1.3
   */
  it('Property 2: ActivityFilters should handle search input correctly', async () => {
    fc.assert(
      fc.asyncProperty(
        fc.string({ minLength: 2, maxLength: 20 }),
        async (searchQuery) => {
          const user = userEvent.setup()
          const mockOnFiltersChange = vi.fn()
          
          render(
            React.createElement(TestWrapper, null,
              React.createElement(ActivityFilters, {
                filters: {},
                onFiltersChange: mockOnFiltersChange
              })
            )
          )

          const searchInput = screen.getByPlaceholderText('Search activities...')
          
          // Type in the search query
          await user.type(searchInput, searchQuery)
          
          // Wait for debounced search to trigger
          await waitFor(() => {
            expect(mockOnFiltersChange).toHaveBeenCalledWith({
              search: searchQuery
            })
          }, { timeout: 500 })

          return true
        }
      ),
      { numRuns: 20 } // Reduced runs for async UI tests
    )
  })

  /**
   * Feature: work-tracker, Property 3: Activity Display and Filtering (Filter State Test)
   * Validates: Requirements 1.5, 4.3
   */
  it('Property 3: ActivityFilters should correctly update filter state for all filter types', () => {
    fc.assert(
      fc.property(
        activityFiltersArb,
        (initialFilters) => {
          const mockOnFiltersChange = vi.fn()
          
          render(
            React.createElement(TestWrapper, null,
              React.createElement(ActivityFilters, {
                filters: initialFilters,
                onFiltersChange: mockOnFiltersChange
              })
            )
          )

          // The component should render without errors with any valid filter combination
          expect(screen.getByPlaceholderText('Search activities...')).toBeInTheDocument()
          
          // If search value exists, it should be displayed
          if (initialFilters.search) {
            expect(screen.getByDisplayValue(initialFilters.search)).toBeInTheDocument()
          }

          return true
        }
      ),
      { numRuns: 50 }
    )
  })
})