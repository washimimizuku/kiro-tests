import axios from 'axios';
import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  User,
  Observation,
  ObservationWithUser,
  ObservationWithDistance,
  CreateObservationRequest,
  UpdateObservationRequest,
  Trip,
  CreateTripRequest,
  UpdateTripRequest,
  TripWithObservations,
  ProximitySearchParams,
} from '../types';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    // Handle network errors
    if (!error.response) {
      error.message = 'Network error. Please check your connection and try again.';
      return Promise.reject(error);
    }

    // Handle 401 Unauthorized
    if (error.response.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
      error.message = 'Your session has expired. Please log in again.';
      return Promise.reject(error);
    }

    // Extract error message from response
    const errorData = error.response.data;
    if (errorData?.error?.message) {
      error.message = errorData.error.message;
    } else if (typeof errorData === 'string') {
      error.message = errorData;
    } else {
      // Default error messages based on status code
      switch (error.response.status) {
        case 400:
          error.message = 'Invalid request. Please check your input.';
          break;
        case 403:
          error.message = 'You do not have permission to perform this action.';
          break;
        case 404:
          error.message = 'The requested resource was not found.';
          break;
        case 409:
          error.message = 'This resource already exists.';
          break;
        case 500:
          error.message = 'Server error. Please try again later.';
          break;
        default:
          error.message = 'An unexpected error occurred. Please try again.';
      }
    }

    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  register: async (data: RegisterRequest): Promise<User> => {
    const response = await api.post<User>('/api/auth/register', data);
    return response.data;
  },

  login: async (data: LoginRequest): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/api/auth/login', data);
    return response.data;
  },

  getMe: async (): Promise<User> => {
    const response = await api.get<User>('/api/users/me');
    return response.data;
  },
};

// Observations API
export const observationsAPI = {
  create: async (data: CreateObservationRequest): Promise<Observation> => {
    const response = await api.post<Observation>('/api/observations', data);
    return response.data;
  },

  getAll: async (): Promise<Observation[]> => {
    const response = await api.get<Observation[]>('/api/observations');
    return response.data;
  },

  getById: async (id: string): Promise<Observation> => {
    const response = await api.get<Observation>(`/api/observations/${id}`);
    return response.data;
  },

  update: async (id: string, data: UpdateObservationRequest): Promise<Observation> => {
    const response = await api.put<Observation>(`/api/observations/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/api/observations/${id}`);
  },

  getShared: async (): Promise<ObservationWithUser[]> => {
    const response = await api.get<ObservationWithUser[]>('/api/observations/shared');
    return response.data;
  },

  search: async (params: {
    species?: string;
    location?: string;
    start_date?: string;
    end_date?: string;
  }): Promise<Observation[]> => {
    const response = await api.get<Observation[]>('/api/observations/search', { params });
    return response.data;
  },

  getNearby: async (params: ProximitySearchParams): Promise<ObservationWithDistance[]> => {
    const response = await api.get<ObservationWithDistance[]>('/api/observations/nearby', { params });
    return response.data;
  },
};

// Trips API
export const tripsAPI = {
  create: async (data: CreateTripRequest): Promise<Trip> => {
    const response = await api.post<Trip>('/api/trips', data);
    return response.data;
  },

  getAll: async (): Promise<Trip[]> => {
    const response = await api.get<Trip[]>('/api/trips');
    return response.data;
  },

  getById: async (id: string): Promise<TripWithObservations> => {
    const response = await api.get<TripWithObservations>(`/api/trips/${id}`);
    return response.data;
  },

  update: async (id: string, data: UpdateTripRequest): Promise<Trip> => {
    const response = await api.put<Trip>(`/api/trips/${id}`, data);
    return response.data;
  },

  delete: async (id: string): Promise<void> => {
    await api.delete(`/api/trips/${id}`);
  },
};

// Photos API
export const photosAPI = {
  upload: async (file: File): Promise<{ photo_url: string }> => {
    const formData = new FormData();
    formData.append('file', file);

    const response = await api.post<{ photo_url: string }>('/api/photos/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },
};

export default api;
