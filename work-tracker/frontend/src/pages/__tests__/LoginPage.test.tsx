import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { BrowserRouter } from 'react-router-dom'
import LoginPage from '../LoginPage'
import { AuthProvider } from '@/contexts/AuthContext'
import toast from 'react-hot-toast'

// Mock react-hot-toast
vi.mock('react-hot-toast', () => ({
  default: {
    success: vi.fn(),
    error: vi.fn(),
  },
}))

// Mock the auth context
const mockAuthContext = {
  user: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,
  login: vi.fn(),
  logout: vi.fn(),
  clearError: vi.fn(),
}

vi.mock('@/contexts/AuthContext', () => ({
  AuthProvider: ({ children }: { children: React.ReactNode }) => children,
  useAuth: () => mockAuthContext,
}))

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      <AuthProvider>
        {component}
      </AuthProvider>
    </BrowserRouter>
  )
}

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockAuthContext.isLoading = false
    mockAuthContext.isAuthenticated = false
    mockAuthContext.error = null
  })

  it('renders login form correctly', () => {
    renderWithRouter(<LoginPage />)

    expect(screen.getByText('Sign in to Work Tracker')).toBeInTheDocument()
    expect(screen.getByLabelText('Email address')).toBeInTheDocument()
    expect(screen.getByLabelText('Password')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  it('shows error message when there is an authentication error', () => {
    mockAuthContext.error = 'Invalid credentials'

    renderWithRouter(<LoginPage />)

    expect(screen.getByText('Invalid credentials')).toBeInTheDocument()
  })

  it('shows loading state when authentication is in progress', () => {
    mockAuthContext.isLoading = true

    renderWithRouter(<LoginPage />)

    expect(screen.getByText('Signing in...')).toBeInTheDocument()
    expect(screen.getByRole('button')).toBeDisabled()
  })

  it('calls login function when form is submitted with valid data', async () => {
    const user = userEvent.setup()
    mockAuthContext.login.mockResolvedValue(undefined)

    renderWithRouter(<LoginPage />)

    const emailInput = screen.getByLabelText('Email address')
    const passwordInput = screen.getByLabelText('Password')
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    await user.click(submitButton)

    expect(mockAuthContext.login).toHaveBeenCalledWith('test@example.com', 'password123')
  })

  it('shows success toast on successful login', async () => {
    const user = userEvent.setup()
    mockAuthContext.login.mockResolvedValue(undefined)

    renderWithRouter(<LoginPage />)

    const emailInput = screen.getByLabelText('Email address')
    const passwordInput = screen.getByLabelText('Password')
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    await user.click(submitButton)

    await waitFor(() => {
      expect(toast.success).toHaveBeenCalledWith('Successfully logged in!')
    })
  })

  it('shows error toast on login failure', async () => {
    const user = userEvent.setup()
    const errorMessage = 'Login failed'
    mockAuthContext.login.mockRejectedValue({
      response: { data: { message: errorMessage } }
    })

    renderWithRouter(<LoginPage />)

    const emailInput = screen.getByLabelText('Email address')
    const passwordInput = screen.getByLabelText('Password')
    const submitButton = screen.getByRole('button', { name: /sign in/i })

    await user.type(emailInput, 'test@example.com')
    await user.type(passwordInput, 'password123')
    await user.click(submitButton)

    await waitFor(() => {
      expect(toast.error).toHaveBeenCalledWith(errorMessage)
    })
  })

  it('clears error when input values change', async () => {
    const user = userEvent.setup()
    mockAuthContext.error = 'Some error'

    renderWithRouter(<LoginPage />)

    const emailInput = screen.getByLabelText('Email address')
    
    await user.type(emailInput, 'a')

    expect(mockAuthContext.clearError).toHaveBeenCalled()
  })

  it('has link to registration page', () => {
    renderWithRouter(<LoginPage />)

    const signUpLink = screen.getByRole('link', { name: /sign up/i })
    expect(signUpLink).toBeInTheDocument()
    expect(signUpLink).toHaveAttribute('href', '/register')
  })
})