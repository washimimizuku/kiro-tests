import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, act } from '@testing-library/react'
import { AuthProvider, useAuth } from '../AuthContext'
import { apiPost } from '@/utils/api'

// Mock the API utility
vi.mock('@/utils/api', () => ({
  apiPost: vi.fn(),
}))

// Mock localStorage
const mockLocalStorage = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
}
Object.defineProperty(window, 'localStorage', {
  value: mockLocalStorage,
})

// Test component that uses the auth context
const TestComponent = () => {
  const { user, isAuthenticated, isLoading, error, login, logout } = useAuth()
  
  return (
    <div>
      <div data-testid="user">{user?.name || 'No user'}</div>
      <div data-testid="authenticated">{isAuthenticated.toString()}</div>
      <div data-testid="loading">{isLoading.toString()}</div>
      <div data-testid="error">{error || 'No error'}</div>
      <button onClick={() => login('test@example.com', 'password')}>Login</button>
      <button onClick={logout}>Logout</button>
    </div>
  )
}

describe('AuthContext', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockLocalStorage.getItem.mockReturnValue(null)
  })

  it('provides initial auth state', () => {
    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    expect(screen.getByTestId('user')).toHaveTextContent('No user')
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
    expect(screen.getByTestId('loading')).toHaveTextContent('false')
    expect(screen.getByTestId('error')).toHaveTextContent('No error')
  })

  it('restores user session from localStorage on mount', () => {
    const mockUser = { id: '1', name: 'Test User', email: 'test@example.com' }
    mockLocalStorage.getItem.mockImplementation((key) => {
      if (key === 'accessToken') return 'mock-token'
      if (key === 'user') return JSON.stringify(mockUser)
      if (key === 'refreshToken') return 'mock-refresh-token'
      return null
    })

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    expect(screen.getByTestId('user')).toHaveTextContent('Test User')
    expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
  })

  it('handles successful login', async () => {
    const mockUser = { id: '1', name: 'Test User', email: 'test@example.com' }
    const mockResponse = {
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresIn: 3600,
      user: mockUser,
    }

    vi.mocked(apiPost).mockResolvedValue(mockResponse)

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    const loginButton = screen.getByText('Login')
    
    await act(async () => {
      loginButton.click()
    })

    expect(apiPost).toHaveBeenCalledWith('/auth/login', {
      email: 'test@example.com',
      password: 'password',
    })

    expect(mockLocalStorage.setItem).toHaveBeenCalledWith('accessToken', 'mock-access-token')
    expect(mockLocalStorage.setItem).toHaveBeenCalledWith('refreshToken', 'mock-refresh-token')
    expect(mockLocalStorage.setItem).toHaveBeenCalledWith('user', JSON.stringify(mockUser))

    expect(screen.getByTestId('user')).toHaveTextContent('Test User')
    expect(screen.getByTestId('authenticated')).toHaveTextContent('true')
  })

  it('handles login failure', async () => {
    const errorMessage = 'Invalid credentials'
    vi.mocked(apiPost).mockRejectedValue({
      response: { data: { message: errorMessage } }
    })

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    const loginButton = screen.getByText('Login')
    
    await act(async () => {
      loginButton.click()
    })

    expect(screen.getByTestId('error')).toHaveTextContent(errorMessage)
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
  })

  it('handles logout', async () => {
    // First set up authenticated state
    const mockUser = { id: '1', name: 'Test User', email: 'test@example.com' }
    mockLocalStorage.getItem.mockImplementation((key) => {
      if (key === 'accessToken') return 'mock-token'
      if (key === 'user') return JSON.stringify(mockUser)
      return null
    })

    render(
      <AuthProvider>
        <TestComponent />
      </AuthProvider>
    )

    // Verify user is authenticated
    expect(screen.getByTestId('authenticated')).toHaveTextContent('true')

    const logoutButton = screen.getByText('Logout')
    
    act(() => {
      logoutButton.click()
    })

    expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('accessToken')
    expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('refreshToken')
    expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('user')

    expect(screen.getByTestId('user')).toHaveTextContent('No user')
    expect(screen.getByTestId('authenticated')).toHaveTextContent('false')
  })

  it('throws error when useAuth is used outside AuthProvider', () => {
    // Suppress console.error for this test
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    expect(() => {
      render(<TestComponent />)
    }).toThrow('useAuth must be used within an AuthProvider')

    consoleSpy.mockRestore()
  })
})