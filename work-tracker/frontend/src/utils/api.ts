import axios, { AxiosInstance, AxiosResponse } from 'axios'
import { ApiResponse } from '@/types'

// Create axios instance with base configuration
const api: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Handle 401 errors (unauthorized)
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        const refreshToken = localStorage.getItem('refreshToken')
        if (refreshToken) {
          const response = await api.post('/auth/refresh', {
            refreshToken,
          })
          
          const { accessToken } = response.data
          localStorage.setItem('accessToken', accessToken)
          
          // Retry original request with new token
          originalRequest.headers.Authorization = `Bearer ${accessToken}`
          return api(originalRequest)
        }
      } catch (refreshError) {
        // Refresh failed, redirect to login
        localStorage.removeItem('accessToken')
        localStorage.removeItem('refreshToken')
        window.location.href = '/login'
      }
    }

    return Promise.reject(error)
  }
)

// Generic API wrapper functions
export const apiGet = async <T>(url: string): Promise<T> => {
  const response = await api.get<ApiResponse<T>>(url)
  return response.data.data
}

export const apiPost = async <T, D = any>(url: string, data?: D): Promise<T> => {
  const response = await api.post<ApiResponse<T>>(url, data)
  return response.data.data
}

export const apiPut = async <T, D = any>(url: string, data?: D): Promise<T> => {
  const response = await api.put<ApiResponse<T>>(url, data)
  return response.data.data
}

export const apiDelete = async <T>(url: string): Promise<T> => {
  const response = await api.delete<ApiResponse<T>>(url)
  return response.data.data
}

export default api