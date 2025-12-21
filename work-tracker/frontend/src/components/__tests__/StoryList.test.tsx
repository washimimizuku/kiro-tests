import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from 'react-query'
import StoryList from '../StoryList'
import { Story, StoryStatus } from '@/types'

// Mock the hooks
const mockDeleteStory = vi.fn()
const mockEnhanceStory = vi.fn()

vi.mock('@/hooks/useStories', () => ({
  useDeleteStory: () => ({
    mutateAsync: mockDeleteStory,
  }),
  useEnhanceStory: () => ({
    mutateAsync: mockEnhanceStory,
  }),
}))

// Mock react-hot-toast
vi.mock('react-hot-toast', () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

// Mock window.confirm
Object.defineProperty(window, 'confirm', {
  writable: true,
  value: vi.fn(),
})

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

const mockStories: Story[] = [
  {
    id: '1',
    userId: 'user1',
    title: 'Customer Success Story',
    situation: 'Customer was facing performance issues with their application...',
    task: 'Needed to optimize the database queries and improve response times',
    action: 'Implemented query optimization and caching strategies',
    result: 'Reduced response time by 80% and improved customer satisfaction',
    impactMetrics: { responseTime: '80% improvement' },
    tags: ['performance', 'database'],
    status: StoryStatus.COMPLETE,
    aiEnhanced: false,
    createdAt: '2023-12-01T10:00:00Z',
    updatedAt: '2023-12-01T10:00:00Z',
  },
  {
    id: '2',
    userId: 'user1',
    title: 'AI Enhanced Story',
    situation: 'Another customer situation...',
    task: 'Task description',
    action: 'Action taken',
    result: 'Great results achieved',
    impactMetrics: {},
    tags: ['ai', 'automation'],
    status: StoryStatus.PUBLISHED,
    aiEnhanced: true,
    createdAt: '2023-12-02T10:00:00Z',
    updatedAt: '2023-12-02T10:00:00Z',
  },
  {
    id: '3',
    userId: 'user1',
    title: 'Draft Story',
    situation: 'Incomplete situation',
    task: '',
    action: '',
    result: '',
    impactMetrics: {},
    tags: [],
    status: StoryStatus.DRAFT,
    aiEnhanced: false,
    createdAt: '2023-12-03T10:00:00Z',
    updatedAt: '2023-12-03T10:00:00Z',
  },
]

describe('StoryList', () => {
  const mockOnEdit = vi.fn()
  const mockOnView = vi.fn()

  beforeEach(() => {
    vi.clearAllMocks()
    mockDeleteStory.mockResolvedValue(undefined)
    mockEnhanceStory.mockResolvedValue(mockStories[0])
  })

  it('renders stories with correct information', () => {
    renderWithQueryClient(
      <StoryList 
        stories={mockStories} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    // Check story titles
    expect(screen.getByText('Customer Success Story')).toBeInTheDocument()
    expect(screen.getByText('AI Enhanced Story')).toBeInTheDocument()
    expect(screen.getByText('Draft Story')).toBeInTheDocument()

    // Check status badges
    expect(screen.getByText('Complete')).toBeInTheDocument()
    expect(screen.getByText('Published')).toBeInTheDocument()
    expect(screen.getByText('Draft')).toBeInTheDocument()

    // Check AI enhanced badge
    expect(screen.getByText('AI Enhanced')).toBeInTheDocument()

    // Check tags
    expect(screen.getByText('performance')).toBeInTheDocument()
    expect(screen.getByText('database')).toBeInTheDocument()
    expect(screen.getByText('ai')).toBeInTheDocument()
    expect(screen.getByText('automation')).toBeInTheDocument()
  })

  it('shows completeness indicators', () => {
    renderWithQueryClient(
      <StoryList 
        stories={mockStories} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    // Complete story should show 100%
    const completeStoryCard = screen.getByText('Customer Success Story').closest('.card')
    expect(completeStoryCard).toHaveTextContent('100%')

    // Draft story should show 25% (only situation filled)
    const draftStoryCard = screen.getByText('Draft Story').closest('.card')
    expect(draftStoryCard).toHaveTextContent('25%')
  })

  it('opens action menu when clicking more button', async () => {
    renderWithQueryClient(
      <StoryList 
        stories={[mockStories[0]]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const moreButton = screen.getByRole('button', { name: '' }) // MoreVertical icon
    fireEvent.click(moreButton)

    // Check menu items
    expect(screen.getByText('View')).toBeInTheDocument()
    expect(screen.getByText('Edit')).toBeInTheDocument()
    expect(screen.getByText('AI Enhance')).toBeInTheDocument()
    expect(screen.getByText('Export')).toBeInTheDocument()
    expect(screen.getByText('Share')).toBeInTheDocument()
    expect(screen.getByText('Delete')).toBeInTheDocument()
  })

  it('calls onView when view is clicked', async () => {
    renderWithQueryClient(
      <StoryList 
        stories={[mockStories[0]]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const moreButton = screen.getByRole('button', { name: '' })
    fireEvent.click(moreButton)

    const viewButton = screen.getByText('View')
    fireEvent.click(viewButton)

    expect(mockOnView).toHaveBeenCalledWith(mockStories[0])
  })

  it('calls onEdit when edit is clicked', async () => {
    renderWithQueryClient(
      <StoryList 
        stories={[mockStories[0]]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const moreButton = screen.getByRole('button', { name: '' })
    fireEvent.click(moreButton)

    const editButton = screen.getByText('Edit')
    fireEvent.click(editButton)

    expect(mockOnEdit).toHaveBeenCalledWith(mockStories[0])
  })

  it('handles story enhancement', async () => {
    renderWithQueryClient(
      <StoryList 
        stories={[mockStories[0]]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const moreButton = screen.getByRole('button', { name: '' })
    fireEvent.click(moreButton)

    const enhanceButton = screen.getByText('AI Enhance')
    fireEvent.click(enhanceButton)

    await waitFor(() => {
      expect(mockEnhanceStory).toHaveBeenCalledWith('1')
    })
  })

  it('handles story deletion with confirmation', async () => {
    vi.mocked(window.confirm).mockReturnValue(true)

    renderWithQueryClient(
      <StoryList 
        stories={[mockStories[0]]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const moreButton = screen.getByRole('button', { name: '' })
    fireEvent.click(moreButton)

    const deleteButton = screen.getByText('Delete')
    fireEvent.click(deleteButton)

    expect(window.confirm).toHaveBeenCalledWith(
      'Are you sure you want to delete this story? This action cannot be undone.'
    )

    await waitFor(() => {
      expect(mockDeleteStory).toHaveBeenCalledWith('1')
    })
  })

  it('cancels deletion when user declines confirmation', async () => {
    vi.mocked(window.confirm).mockReturnValue(false)

    renderWithQueryClient(
      <StoryList 
        stories={[mockStories[0]]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const moreButton = screen.getByRole('button', { name: '' })
    fireEvent.click(moreButton)

    const deleteButton = screen.getByText('Delete')
    fireEvent.click(deleteButton)

    expect(window.confirm).toHaveBeenCalled()
    expect(mockDeleteStory).not.toHaveBeenCalled()
  })

  it('shows loading state', () => {
    renderWithQueryClient(
      <StoryList 
        stories={[]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
        isLoading={true}
      />
    )

    // Should show loading skeletons - check for animate-pulse class
    expect(screen.getAllByText('', { selector: '.animate-pulse' })).toHaveLength(3)
  })

  it('shows empty state when no stories', () => {
    renderWithQueryClient(
      <StoryList 
        stories={[]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    expect(screen.getByText('No stories found')).toBeInTheDocument()
    expect(screen.getByText(/start by creating your first customer success story/i)).toBeInTheDocument()
  })

  it('truncates long story previews', () => {
    const longStory = {
      ...mockStories[0],
      situation: 'A'.repeat(300), // Very long situation
    }

    renderWithQueryClient(
      <StoryList 
        stories={[longStory]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    const storyCard = screen.getByText('Customer Success Story').closest('.card')
    expect(storyCard).toHaveTextContent('...')
  })

  it('limits displayed tags and shows count for additional tags', () => {
    const storyWithManyTags = {
      ...mockStories[0],
      tags: ['tag1', 'tag2', 'tag3', 'tag4', 'tag5'],
    }

    renderWithQueryClient(
      <StoryList 
        stories={[storyWithManyTags]} 
        onEdit={mockOnEdit}
        onView={mockOnView}
      />
    )

    // Should show first 3 tags
    expect(screen.getByText('tag1')).toBeInTheDocument()
    expect(screen.getByText('tag2')).toBeInTheDocument()
    expect(screen.getByText('tag3')).toBeInTheDocument()

    // Should show "+2 more" for remaining tags
    expect(screen.getByText('+2 more')).toBeInTheDocument()
  })
})