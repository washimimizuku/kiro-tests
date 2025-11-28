/**
 * Coordinate formatting and validation utilities for geolocation features
 */

/**
 * Format a coordinate value with 6 decimal places precision
 * @param value - The coordinate value (latitude or longitude)
 * @param type - The type of coordinate ('lat' or 'lng')
 * @returns Formatted coordinate string with 6 decimal places
 */
export function formatCoordinate(value: number, type: 'lat' | 'lng'): string {
  return value.toFixed(6);
}

/**
 * Format coordinates with directional indicators (N/S for latitude, E/W for longitude)
 * @param lat - Latitude value
 * @param lng - Longitude value
 * @returns Formatted string with directional indicators (e.g., "40.712800°N, 74.006000°W")
 */
export function formatCoordinateWithDirection(lat: number, lng: number): string {
  const latDirection = lat >= 0 ? 'N' : 'S';
  const lngDirection = lng >= 0 ? 'E' : 'W';
  const absLat = Math.abs(lat);
  const absLng = Math.abs(lng);
  
  return `${absLat.toFixed(6)}°${latDirection}, ${absLng.toFixed(6)}°${lngDirection}`;
}

/**
 * Format coordinates for GPS devices in decimal degrees format
 * @param lat - Latitude value
 * @param lng - Longitude value
 * @returns Formatted string suitable for GPS devices (e.g., "40.712800, -74.006000")
 */
export function formatForGPS(lat: number, lng: number): string {
  return `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
}

/**
 * Validate that a latitude value is within valid bounds (-90 to 90)
 * @param lat - Latitude value to validate
 * @returns true if latitude is valid, false otherwise
 */
export function isValidLatitude(lat: number): boolean {
  return !isNaN(lat) && lat >= -90 && lat <= 90;
}

/**
 * Validate that a longitude value is within valid bounds (-180 to 180)
 * @param lng - Longitude value to validate
 * @returns true if longitude is valid, false otherwise
 */
export function isValidLongitude(lng: number): boolean {
  return !isNaN(lng) && lng >= -180 && lng <= 180;
}

/**
 * Check if an observation has valid coordinates
 * @param observation - Observation to check
 * @returns true if observation has both latitude and longitude
 */
export function hasCoordinates(observation: { latitude?: number; longitude?: number }): boolean {
  return observation.latitude !== undefined && 
         observation.latitude !== null && 
         observation.longitude !== undefined && 
         observation.longitude !== null;
}

/**
 * Filter observations to only those with coordinates
 * @param observations - Array of observations
 * @returns Array of observations that have both latitude and longitude
 */
export function filterObservationsWithCoordinates<T extends { latitude?: number; longitude?: number }>(
  observations: T[]
): T[] {
  return observations.filter(hasCoordinates);
}

/**
 * Filter shared observations to only those with coordinates
 * @param observations - Array of observations
 * @returns Array of shared observations that have both latitude and longitude
 */
export function filterSharedObservationsWithCoordinates<T extends { latitude?: number; longitude?: number; is_shared: boolean }>(
  observations: T[]
): T[] {
  return observations.filter(obs => obs.is_shared && hasCoordinates(obs));
}

/**
 * Filter trip observations to only those with coordinates
 * @param observations - Array of observations
 * @param tripId - ID of the trip to filter by
 * @returns Array of observations from the specified trip that have both latitude and longitude
 */
export function filterTripObservationsWithCoordinates<T extends { latitude?: number; longitude?: number; trip_id?: string }>(
  observations: T[],
  tripId: string
): T[] {
  return observations.filter(obs => obs.trip_id === tripId && hasCoordinates(obs));
}
