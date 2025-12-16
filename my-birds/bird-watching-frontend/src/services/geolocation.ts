/**
 * Geolocation service for accessing browser GPS capabilities
 */

import type { GeolocationCoordinates } from '../types';
import { GeolocationErrorType, GeolocationError } from '../types';

/**
 * Check if geolocation is supported by the browser
 * @returns true if geolocation API is available
 */
export function isSupported(): boolean {
  return 'geolocation' in navigator;
}

/**
 * Get the current position from the browser's geolocation API
 * @param options - Optional configuration for geolocation request
 * @returns Promise resolving to coordinates
 * @throws GeolocationError if location cannot be obtained
 */
export function getCurrentPosition(
  options?: PositionOptions
): Promise<GeolocationCoordinates> {
  return new Promise((resolve, reject) => {
    if (!isSupported()) {
      reject(
        new GeolocationError(
          GeolocationErrorType.NOT_SUPPORTED,
          'Geolocation is not supported by this browser'
        )
      );
      return;
    }

    const defaultOptions: PositionOptions = {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 0,
      ...options,
    };

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
      },
      (error) => {
        let errorType: GeolocationErrorType;
        let errorMessage: string;

        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorType = GeolocationErrorType.PERMISSION_DENIED;
            errorMessage =
              'Location access denied. Please enable location permissions or enter coordinates manually.';
            break;
          case error.POSITION_UNAVAILABLE:
            errorType = GeolocationErrorType.POSITION_UNAVAILABLE;
            errorMessage =
              'Unable to determine your location. Please enter coordinates manually.';
            break;
          case error.TIMEOUT:
            errorType = GeolocationErrorType.TIMEOUT;
            errorMessage =
              'Location request timed out. Please try again or enter coordinates manually.';
            break;
          default:
            errorType = GeolocationErrorType.POSITION_UNAVAILABLE;
            errorMessage = 'An unknown error occurred while getting your location.';
        }

        reject(new GeolocationError(errorType, errorMessage));
      },
      defaultOptions
    );
  });
}

/**
 * Request permission for geolocation (if supported by browser)
 * Note: Most browsers don't support explicit permission requests,
 * permission is requested when getCurrentPosition is called
 * @returns Promise resolving to permission state
 */
export async function requestPermission(): Promise<PermissionState> {
  if (!isSupported()) {
    return 'denied';
  }

  // Check if Permissions API is available
  if ('permissions' in navigator) {
    try {
      const result = await navigator.permissions.query({ name: 'geolocation' });
      return result.state;
    } catch (error) {
      // Permissions API not fully supported, return 'prompt'
      return 'prompt';
    }
  }

  // Permissions API not available
  return 'prompt';
}
