import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { QueryClient, QueryClientProvider } from 'react-query'
import StoryForm from '../StoryForm'
import { StoryCreateRequest, StoryStatus } from '@/types'

// Mock the hooks
vi.mock('@/hooks/useStories', () => ({
  useStoryTags: () => ({
    data: ['customer-success', 'technical', 'performance'],
  }),
  useEnhanceStory: () => ({
    mutateAsync: vi.fn().mockResolvedValue({
      id: '1',
      situation: 'Enhanced situation',
      task: 'Enhanced task',
      action: 'Enhanced action',
      result: 'Enhanced result',
      impactMetrics: { improvement: '50%' },
    }),
  }),
}))

// Mock react-hot-toast
vi.mock('react-hot-toast', () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
  },
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

describe('StoryForm', () => {
  const mockOnSubmit = vi.fn()
  const user = userEvent.setup()

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders STAR format template interface', () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    // Check for STAR format sections
    expect(screen.getByLabelText(/situation/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/task/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/action/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/result/i)).toBeInTheDocument()

    // Check for STAR format guidance
    expect(screen.getByText('STAR Format')).toBeInTheDocument()
    expect(screen.getByText(/structure your story using the star method/i)).toBeInTheDocument()
  })

  it('shows completeness indicator', () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    // Should show 0% completeness initially
    expect(screen.getByText('0%')).toBeInTheDocument()
  })

  it('updates completeness as sections are filled', async () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    const titleInput = screen.getByLabelText(/story title/i)
    const situationInput = screen.getByLabelText(/situation/i)

    // Fill title (doesn't count toward STAR completeness)
    await user.type(titleInput, 'Test Story')

    // Fill situation (25% of STAR sections)
    await user.type(situationInput, 'Test situation')

    await waitFor(() => {
      expect(screen.getByText('25%')).toBeInTheDocument()
    })
  })

  it('shows story guidance when incomplete', () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    expect(screen.getByText('Story Incomplete')).toBeInTheDocument()
    expect(screen.getByText(/complete all star sections/i)).toBeInTheDocument()
  })

  it('validates required fields', async () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    const submitButton = screen.getByRole('button', { name: /create story/i })
    await user.click(submitButton)

    await waitFor(() => {
      expect(screen.getByText('Title is required')).toBeInTheDocument()
      expect(screen.getByText('Situation is required')).toBeInTheDocument()
      expect(screen.getByText('Task is required')).toBeInTheDocument()
      expect(screen.getByText('Action is required')).toBeInTheDocument()
      expect(screen.getByText('Result is required')).toBeInTheDocument()
    })

    expect(mockOnSubmit).not.toHaveBeenCalled()
  })

  it('submits form with valid data', async () => {
    const mockSubmit = vi.fn().mockResolvedValue(undefined)
    
    renderWithQueryClient(
      <StoryForm onSubmit={mockSubmit} />
    )

    // Fill all required fields
    await user.type(screen.getByLabelText(/story title/i), 'Test Story')
    await user.type(screen.getByLabelText(/situation/i), 'Test situation')
    await user.type(screen.getByLabelText(/task/i), 'Test task')
    await user.type(screen.getByLabelText(/action/i), 'Test action')
    await user.type(screen.getByLabelText(/result/i), 'Test result')

    const submitButton = screen.getByRole('button', { name: /create story/i })
    await user.click(submitButton)

    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        title: 'Test Story',
        situation: 'Test situation',
        task: 'Test task',
        action: 'Test action',
        result: 'Test result',
        impactMetrics: {},
        tags: [],
      })
    })
  })

  it('handles tag input and suggestions', async () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    const tagInput = screen.getByPlaceholderText(/type to add tags/i)
    
    // Type to trigger suggestions
    await user.type(tagInput, 'cust')
    
    await waitFor(() => {
      expect(screen.getByText('customer-success')).toBeInTheDocument()
    })

    // Click suggestion
    await user.click(screen.getByText('customer-success'))

    // Tag should be added
    expect(screen.getByText('customer-success')).toBeInTheDocument()
    expect(tagInput).toHaveValue('')
  })

  it('allows adding custom tags with Enter key', async () => {
    renderWithQueryClient(
      <StoryForm onSubmit={mockOnSubmit} />
    )

    const tagInput = screen.getByPlaceholderText(/type to add tags/i)
    
    await user.type(tagInput, 'custom-tag')
    await user.keyboard('{Enter}')

    expect(screen.getByText('custom-tag')).toBeInTheDocument()
    expect(tagInput).toHaveValue('')
  })

  it('allows removing tags', async () => {
    renderWithQueryClient(
      <StoryForm 
        onSubmit={mockOnSubmit} 
        initialData={{ tags: ['existing-tag'] }}
      />
    )

    expect(screen.getByText('existing-tag')).toBeInTheDocument()

    const removeButton = screen.getByRole('button', { name: '' }) // X button
    await user.click(removeButton)

    expect(screen.queryByText('existing-tag')).not.toBeInTheDocument()
  })

  it('shows AI enhance button in edit mode', () => {
    renderWithQueryClient(
      <StoryForm 
        onSubmit={mockOnSubmit}
        initialData={{ id: '1', status: StoryStatus.COMPLETE }}
        mode="edit"
      />
    )

    expect(screen.getByRole('button', { name: /ai enhance/i })).toBeInTheDocument()
  })

  it('disables AI enhance button when story is incomplete', () => {
    renderWithQueryClient(
      <StoryForm 
        onSubmit={mockOnSubmit}
        initialData={{ id: '1', status: StoryStatus.DRAFT }}
        mode="edit"
      />
    )

    const enhanceButton = screen.getByRole('button', { name: /ai enhance/i })
    expect(enhanceButton).toBeDisabled()
  })

  it('populates form with initial data in edit mode', () => {
    const initialData = {
      title: 'Existing Story',
      situation: 'Existing situation',
      task: 'Existing task',
      action: 'Existing action',
      result: 'Existing result',
      tags: ['existing-tag'],
    }

    renderWithQueryClient(
      <StoryForm 
        onSubmit={mockOnSubmit}
        initialData={initialData}
        mode="edit"
      />
    )

    expect(screen.getByDisplayValue('Existing Story')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Existing situation')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Existing task')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Existing action')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Existing result')).toBeInTheDocument()
    expect(screen.getByText('existing-tag')).toBeInTheDocument()
  })

  it('shows correct button text for edit mode', () => {
    renderWithQueryClient(
      <StoryForm 
        onSubmit={mockOnSubmit}
        mode="edit"
      />
    )

    expect(screen.getByRole('button', { name: /update story/i })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /create story/i })).not.toBeInTheDocument()
  })

  it('shows loading state', () => {
    renderWithQueryClient(
      <StoryForm 
        onSubmit={mockOnSubmit}
        isLoading={true}
      />
    )

    const submitButton = screen.getByRole('button', { name: /saving/i })
    expect(submitButton).toBeDisabled()
  })
})