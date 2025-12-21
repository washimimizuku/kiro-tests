import { LoginRequest, TokenResponse, User } from '@/types'
import { apiPost, apiGet } from '@/utils/api'

export class AuthService {
  static async login(credentials: LoginRequest): Promise<TokenResponse> {
    return apiPost<TokenResponse>('/auth/login', credentials)
  }

  static async refreshToken(refreshToken: string): Promise<TokenResponse> {
    return apiPost<TokenResponse>('/auth/refresh', { refreshToken })
  }

  static async getCurrentUser(): Promise<User> {
    return apiGet<User>('/auth/me')
  }

  static async logout(): Promise<void> {
    return apiPost<void>('/auth/logout')
  }

  static isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]))
      const currentTime = Date.now() / 1000
      return payload.exp < currentTime
    } catch {
      return true
    }
  }

  static getStoredToken(): string | null {
    return localStorage.getItem('accessToken')
  }

  static getStoredUser(): User | null {
    const userStr = localStorage.getItem('user')
    if (!userStr) return null
    
    try {
      return JSON.parse(userStr)
    } catch {
      return null
    }
  }

  static clearStoredAuth(): void {
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('user')
  }
}