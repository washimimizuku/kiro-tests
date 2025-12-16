export interface User {
  id: string;
  username: string;
  email: string;
  created_at: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface Observation {
  id: string;
  user_id: string;
  trip_id?: string;
  species_name: string;
  observation_date: string;
  location: string;
  latitude?: number;
  longitude?: number;
  notes?: string;
  photo_url?: string;
  is_shared: boolean;
  created_at: string;
  updated_at: string;
}

export interface ObservationWithUser extends Observation {
  username: string;
}

export interface CreateObservationRequest {
  species_name: string;
  observation_date: string;
  location: string;
  latitude?: number;
  longitude?: number;
  notes?: string;
  photo_url?: string;
  trip_id?: string;
  is_shared: boolean;
}

export interface UpdateObservationRequest {
  species_name?: string;
  observation_date?: string;
  location?: string;
  latitude?: number;
  longitude?: number;
  notes?: string;
  photo_url?: string;
  trip_id?: string;
  is_shared?: boolean;
}

export interface Trip {
  id: string;
  user_id: string;
  name: string;
  trip_date: string;
  location: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface CreateTripRequest {
  name: string;
  trip_date: string;
  location: string;
  description?: string;
}

export interface UpdateTripRequest {
  name?: string;
  trip_date?: string;
  location?: string;
  description?: string;
}

export interface TripWithObservations {
  trip: Trip;
  observations: Observation[];
}

export interface ObservationWithDistance extends Observation {
  distance_km: number;
}

export interface ProximitySearchParams {
  lat: number;
  lng: number;
  radius: number;
  user_id?: string;
  species?: string;
}

// Geolocation types
export interface GeolocationCoordinates {
  latitude: number;
  longitude: number;
}

export enum GeolocationErrorType {
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  POSITION_UNAVAILABLE = 'POSITION_UNAVAILABLE',
  TIMEOUT = 'TIMEOUT',
  NOT_SUPPORTED = 'NOT_SUPPORTED',
}

export class GeolocationError extends Error {
  constructor(
    public type: GeolocationErrorType,
    message: string
  ) {
    super(message);
    this.name = 'GeolocationError';
  }
}
