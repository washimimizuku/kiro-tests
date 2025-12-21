import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from 'react-query'
import StoryFilters from '../StoryFilters'
import { StoryFilters as StoryFiltersType, StoryStatus } from '@/types'

// Mock the hooks
vi.mock('@/hooks/useStories', () => ({
  useStoryTags: () => ({
    data: ['customer-success', 'technical', 'performance', 'ai', 'automation'],
  }),
}))

const createQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: { retry: false },
    mutations: { retry: false },
  },
})

const renderWithQueryClient = (component: React.ReactElement) => {
  const queryClient = createQueryClient()
  return render(
    <QueryClientProvider client={queryClient}>
      {component}
    </QueryClientProvider>
  )
}

describe('StoryFilters', () => {
  const mockOnFiltersChange = vi.fn()
  const user = userEvent.setup()

  const defaultProps = {
    filters: {} as StoryFiltersType,
    onFiltersChange: mockOnFiltersChange,
    totalCount: 10,
    filteredCount: 8,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders search input', () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    expect(screen.getByPlaceholderText(/search stories by title or content/i)).toBeInTheDocument()
  })

  it('shows results count', () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    expect(screen.getByText('Showing 8 of 10 stories')).toBeInTheDocument()
    expect(screen.getByText('(2 filtered out)')).toBeInTheDocument()
  })

  it('shows total count when no filters applied', () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filteredCount={10}
      />
    )

    expect(screen.getByText('10 stories total')).toBeInTheDocument()
  })

  it('handles search input with debouncing', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    const searchInput = screen.getByPlaceholderText(/search stories by title or content/i)
    await user.type(searchInput, 'test search')

    // Should debounce the search
    await waitFor(() => {
      expect(mockOnFiltersChange).toHaveBeenCalledWith({
        search: 'test search',
      })
    }, { timeout: 500 })
  })

  it('toggles advanced filters panel', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    // Advanced filters should be visible
    expect(screen.getByText('Status')).toBeInTheDocument()
    expect(screen.getByText('AI Enhancement')).toBeInTheDocument()
    expect(screen.getByText('Tags')).toBeInTheDocument()
  })

  it('handles status filter selection', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    // Click on Draft status
    const draftButton = screen.getByRole('button', { name: 'Draft' })
    await user.click(draftButton)

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      status: StoryStatus.DRAFT,
    })
  })

  it('toggles status filter when clicking same status', async () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ status: StoryStatus.DRAFT }}
      />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    // Click on Draft status again to toggle off
    const draftButton = screen.getByRole('button', { name: 'Draft' })
    await user.click(draftButton)

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      status: undefined,
    })
  })

  it('handles AI enhanced filter', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    // Click on AI Enhanced
    const aiEnhancedButton = screen.getByRole('button', { name: /ai enhanced/i })
    await user.click(aiEnhancedButton)

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      aiEnhanced: true,
    })
  })

  it('handles manual only filter', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    // Click on Manual Only
    const manualOnlyButton = screen.getByRole('button', { name: /manual only/i })
    await user.click(manualOnlyButton)

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      aiEnhanced: false,
    })
  })

  it('handles tag input and suggestions', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    const tagInput = screen.getByPlaceholderText(/type to add tag filters/i)
    
    // Type to trigger suggestions
    await user.type(tagInput, 'cust')
    
    await waitFor(() => {
      expect(screen.getByText('customer-success')).toBeInTheDocument()
    })

    // Click suggestion
    await user.click(screen.getByText('customer-success'))

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      tags: ['customer-success'],
    })
  })

  it('allows adding custom tags with Enter key', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    const tagInput = screen.getByPlaceholderText(/type to add tag filters/i)
    
    await user.type(tagInput, 'custom-tag')
    await user.keyboard('{Enter}')

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      tags: ['custom-tag'],
    })
  })

  it('allows removing tags', async () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ tags: ['existing-tag'] }}
      />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    expect(screen.getByText('existing-tag')).toBeInTheDocument()

    const removeButton = screen.getByRole('button', { name: '' }) // X button
    await user.click(removeButton)

    expect(mockOnFiltersChange).toHaveBeenCalledWith({
      tags: [],
    })
  })

  it('shows active filter count', () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ 
          status: StoryStatus.DRAFT,
          aiEnhanced: true,
          tags: ['tag1', 'tag2'],
        }}
      />
    )

    // Should show count of active filters (status + aiEnhanced + 2 tags = 4)
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    expect(filtersButton).toHaveTextContent('3') // status, aiEnhanced, tags (counted as 1)
  })

  it('shows clear filters button when filters are active', () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ status: StoryStatus.DRAFT }}
      />
    )

    expect(screen.getByRole('button', { name: /clear/i })).toBeInTheDocument()
  })

  it('clears all filters when clear button is clicked', async () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ 
          search: 'test',
          status: StoryStatus.DRAFT,
          aiEnhanced: true,
          tags: ['tag1'],
        }}
      />
    )

    const clearButton = screen.getByRole('button', { name: /clear/i })
    await user.click(clearButton)

    expect(mockOnFiltersChange).toHaveBeenCalledWith({})
  })

  it('highlights filters button when advanced filters are open', async () => {
    renderWithQueryClient(
      <StoryFilters {...defaultProps} />
    )

    const filtersButton = screen.getByRole('button', { name: /filters/i })
    
    // Initially not highlighted
    expect(filtersButton).not.toHaveClass('border-blue-500')

    // Click to open
    await user.click(filtersButton)

    // Should be highlighted when open
    expect(filtersButton).toHaveClass('border-blue-500')
  })

  it('highlights filters button when filters are active', () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ status: StoryStatus.DRAFT }}
      />
    )

    const filtersButton = screen.getByRole('button', { name: /filters/i })
    expect(filtersButton).toHaveClass('border-blue-500')
  })

  it('filters tag suggestions based on already selected tags', async () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ tags: ['customer-success'] }}
      />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    const tagInput = screen.getByPlaceholderText(/type to add tag filters/i)
    
    // Type to trigger suggestions
    await user.type(tagInput, 'c')
    
    await waitFor(() => {
      // Should not show already selected tag
      expect(screen.queryByText('customer-success')).not.toBeInTheDocument()
    })
  })

  it('shows selected status with visual indication', async () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ status: StoryStatus.COMPLETE }}
      />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    const completeButton = screen.getByRole('button', { name: 'Complete' })
    expect(completeButton).toHaveClass('ring-2', 'ring-blue-500')
  })

  it('shows selected AI enhancement filter with visual indication', async () => {
    renderWithQueryClient(
      <StoryFilters 
        {...defaultProps}
        filters={{ aiEnhanced: true }}
      />
    )

    // Open advanced filters
    const filtersButton = screen.getByRole('button', { name: /filters/i })
    await user.click(filtersButton)

    const aiEnhancedButton = screen.getByRole('button', { name: /ai enhanced/i })
    expect(aiEnhancedButton).toHaveClass('ring-2', 'ring-purple-500')
  })
})