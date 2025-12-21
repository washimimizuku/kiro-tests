import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import ProtectedRoute from '../ProtectedRoute'
import { AuthProvider } from '@/contexts/AuthContext'

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

const TestComponent = () => <div>Protected Content</div>

const renderWithRouter = (component: React.ReactElement) => {
  return render(
    <BrowserRouter>
      <AuthProvider>
        {component}
      </AuthProvider>
    </BrowserRouter>
  )
}

describe('ProtectedRoute', () => {
  it('shows loading spinner when authentication is loading', () => {
    mockAuthContext.isLoading = true
    mockAuthContext.isAuthenticated = false

    renderWithRouter(
      <ProtectedRoute>
        <TestComponent />
      </ProtectedRoute>
    )

    expect(screen.getByRole('generic')).toHaveClass('loading-spinner')
  })

  it('renders children when user is authenticated', () => {
    mockAuthContext.isLoading = false
    mockAuthContext.isAuthenticated = true

    renderWithRouter(
      <ProtectedRoute>
        <TestComponent />
      </ProtectedRoute>
    )

    expect(screen.getByText('Protected Content')).toBeInTheDocument()
  })

  it('redirects to login when user is not authenticated', () => {
    mockAuthContext.isLoading = false
    mockAuthContext.isAuthenticated = false

    renderWithRouter(
      <ProtectedRoute>
        <TestComponent />
      </ProtectedRoute>
    )

    // Should not render the protected content
    expect(screen.queryByText('Protected Content')).not.toBeInTheDocument()
  })
})