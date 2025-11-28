import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import {
  isSupported,
  getCurrentPosition,
  requestPermission,
} from './geolocation';
import {
  GeolocationError,
  GeolocationErrorType,
} from '../types';

describe('geolocation service', () => {
  // Mock geolocation API
  const mockGeolocation = {
    getCurrentPosition: vi.fn(),
    watchPosition: vi.fn(),
    clearWatch: vi.fn(),
  };

  // Store original navigator
  const originalNavigator = global.navigator;

  beforeEach(() => {
    // Reset mocks before each test
    vi.clearAllMocks();
    
    // Setup navigator mock with geolocation
    Object.defineProperty(global, 'navigator', {
      writable: true,
      configurable: true,
      value: {
        geolocation: mockGeolocation,
      },
    });
  });

  afterEach(() => {
    // Restore original navigator
    Object.defineProperty(global, 'navigator', {
      writable: true,
      configurable: true,
      value: originalNavigator,
    });
  });

  describe('isSupported', () => {
    it('should return true when geolocation is available', () => {
      expect(isSupported()).toBe(true);
    });

    it('should return false when geolocation is not available', () => {
      Object.defineProperty(global, 'navigator', {
        writable: true,
        configurable: true,
        value: {},
      });
      
      expect(isSupported()).toBe(false);
    });
  });

  describe('getCurrentPosition', () => {
    it('should return coordinates on success', async () => {
      const mockPosition = {
        coords: {
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 10,
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
        },
        timestamp: Date.now(),
      };

      mockGeolocation.getCurrentPosition.mockImplementation((success) => {
        success(mockPosition);
      });

      const result = await getCurrentPosition();

      expect(result).toEqual({
        latitude: 40.7128,
        longitude: -74.0060,
      });
      expect(mockGeolocation.getCurrentPosition).toHaveBeenCalledTimes(1);
    });

    it('should handle permission denied error', async () => {
      const mockError = {
        code: 1, // PERMISSION_DENIED
        message: 'User denied geolocation',
        PERMISSION_DENIED: 1,
        POSITION_UNAVAILABLE: 2,
        TIMEOUT: 3,
      };

      mockGeolocation.getCurrentPosition.mockImplementation((success, error) => {
        error(mockError);
      });

      await expect(getCurrentPosition()).rejects.toThrow(GeolocationError);
      
      try {
        await getCurrentPosition();
      } catch (error) {
        expect(error).toBeInstanceOf(GeolocationError);
        expect((error as GeolocationError).type).toBe(GeolocationErrorType.PERMISSION_DENIED);
        expect((error as GeolocationError).message).toContain('Location access denied');
      }
    });

    it('should handle position unavailable error', async () => {
      const mockError = {
        code: 2, // POSITION_UNAVAILABLE
        message: 'Position unavailable',
        PERMISSION_DENIED: 1,
        POSITION_UNAVAILABLE: 2,
        TIMEOUT: 3,
      };

      mockGeolocation.getCurrentPosition.mockImplementation((success, error) => {
        error(mockError);
      });

      await expect(getCurrentPosition()).rejects.toThrow(GeolocationError);
      
      try {
        await getCurrentPosition();
      } catch (error) {
        expect(error).toBeInstanceOf(GeolocationError);
        expect((error as GeolocationError).type).toBe(GeolocationErrorType.POSITION_UNAVAILABLE);
        expect((error as GeolocationError).message).toContain('Unable to determine your location');
      }
    });

    it('should handle timeout error', async () => {
      const mockError = {
        code: 3, // TIMEOUT
        message: 'Timeout',
        PERMISSION_DENIED: 1,
        POSITION_UNAVAILABLE: 2,
        TIMEOUT: 3,
      };

      mockGeolocation.getCurrentPosition.mockImplementation((success, error) => {
        error(mockError);
      });

      await expect(getCurrentPosition()).rejects.toThrow(GeolocationError);
      
      try {
        await getCurrentPosition();
      } catch (error) {
        expect(error).toBeInstanceOf(GeolocationError);
        expect((error as GeolocationError).type).toBe(GeolocationErrorType.TIMEOUT);
        expect((error as GeolocationError).message).toContain('Location request timed out');
      }
    });

    it('should reject when geolocation is not supported', async () => {
      Object.defineProperty(global, 'navigator', {
        writable: true,
        configurable: true,
        value: {},
      });

      await expect(getCurrentPosition()).rejects.toThrow(GeolocationError);
      
      try {
        await getCurrentPosition();
      } catch (error) {
        expect(error).toBeInstanceOf(GeolocationError);
        expect((error as GeolocationError).type).toBe(GeolocationErrorType.NOT_SUPPORTED);
        expect((error as GeolocationError).message).toContain('not supported');
      }
    });

    it('should pass options to getCurrentPosition', async () => {
      const mockPosition = {
        coords: {
          latitude: 51.5074,
          longitude: -0.1278,
          accuracy: 10,
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
        },
        timestamp: Date.now(),
      };

      mockGeolocation.getCurrentPosition.mockImplementation((success) => {
        success(mockPosition);
      });

      const options = {
        enableHighAccuracy: false,
        timeout: 5000,
        maximumAge: 1000,
      };

      await getCurrentPosition(options);

      expect(mockGeolocation.getCurrentPosition).toHaveBeenCalledWith(
        expect.any(Function),
        expect.any(Function),
        expect.objectContaining(options)
      );
    });

    it('should use default options when none provided', async () => {
      const mockPosition = {
        coords: {
          latitude: 35.6762,
          longitude: 139.6503,
          accuracy: 10,
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
        },
        timestamp: Date.now(),
      };

      mockGeolocation.getCurrentPosition.mockImplementation((success) => {
        success(mockPosition);
      });

      await getCurrentPosition();

      expect(mockGeolocation.getCurrentPosition).toHaveBeenCalledWith(
        expect.any(Function),
        expect.any(Function),
        expect.objectContaining({
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0,
        })
      );
    });
  });

  describe('requestPermission', () => {
    it('should return denied when geolocation is not supported', async () => {
      Object.defineProperty(global, 'navigator', {
        writable: true,
        configurable: true,
        value: {},
      });

      const result = await requestPermission();
      expect(result).toBe('denied');
    });

    it('should return permission state when Permissions API is available', async () => {
      const mockPermissionStatus = {
        state: 'granted' as PermissionState,
      };

      Object.defineProperty(global, 'navigator', {
        writable: true,
        configurable: true,
        value: {
          geolocation: mockGeolocation,
          permissions: {
            query: vi.fn().mockResolvedValue(mockPermissionStatus),
          },
        },
      });

      const result = await requestPermission();
      expect(result).toBe('granted');
    });

    it('should return prompt when Permissions API is not available', async () => {
      Object.defineProperty(global, 'navigator', {
        writable: true,
        configurable: true,
        value: {
          geolocation: mockGeolocation,
        },
      });

      const result = await requestPermission();
      expect(result).toBe('prompt');
    });

    it('should return prompt when Permissions API query fails', async () => {
      Object.defineProperty(global, 'navigator', {
        writable: true,
        configurable: true,
        value: {
          geolocation: mockGeolocation,
          permissions: {
            query: vi.fn().mockRejectedValue(new Error('Not supported')),
          },
        },
      });

      const result = await requestPermission();
      expect(result).toBe('prompt');
    });
  });
});
