import { describe, it, expect } from 'vitest';
import {
  formatCoordinate,
  formatCoordinateWithDirection,
  formatForGPS,
  isValidLatitude,
  isValidLongitude,
} from './coordinateUtils';

describe('coordinateUtils', () => {
  describe('formatCoordinate', () => {
    it('should format coordinate with 6 decimal places', () => {
      expect(formatCoordinate(40.7128, 'lat')).toBe('40.712800');
      expect(formatCoordinate(-74.0060, 'lng')).toBe('-74.006000');
    });

    it('should handle zero values', () => {
      expect(formatCoordinate(0, 'lat')).toBe('0.000000');
      expect(formatCoordinate(0, 'lng')).toBe('0.000000');
    });

    it('should handle boundary values', () => {
      expect(formatCoordinate(90, 'lat')).toBe('90.000000');
      expect(formatCoordinate(-90, 'lat')).toBe('-90.000000');
      expect(formatCoordinate(180, 'lng')).toBe('180.000000');
      expect(formatCoordinate(-180, 'lng')).toBe('-180.000000');
    });

    it('should round to 6 decimal places', () => {
      expect(formatCoordinate(40.71280123456789, 'lat')).toBe('40.712801');
      expect(formatCoordinate(-74.00600987654321, 'lng')).toBe('-74.006010');
    });
  });

  describe('formatCoordinateWithDirection', () => {
    it('should format coordinates with N/E directions for positive values', () => {
      expect(formatCoordinateWithDirection(40.7128, -74.0060)).toBe('40.712800°N, 74.006000°W');
    });

    it('should format coordinates with S/W directions for negative values', () => {
      expect(formatCoordinateWithDirection(-33.8688, 151.2093)).toBe('33.868800°S, 151.209300°E');
    });

    it('should format coordinates in NE quadrant', () => {
      expect(formatCoordinateWithDirection(51.5074, 0.1278)).toBe('51.507400°N, 0.127800°E');
    });

    it('should format coordinates in SE quadrant', () => {
      expect(formatCoordinateWithDirection(-33.8688, 151.2093)).toBe('33.868800°S, 151.209300°E');
    });

    it('should format coordinates in SW quadrant', () => {
      expect(formatCoordinateWithDirection(-23.5505, -46.6333)).toBe('23.550500°S, 46.633300°W');
    });

    it('should format coordinates in NW quadrant', () => {
      expect(formatCoordinateWithDirection(40.7128, -74.0060)).toBe('40.712800°N, 74.006000°W');
    });

    it('should handle zero latitude (equator)', () => {
      expect(formatCoordinateWithDirection(0, 100)).toBe('0.000000°N, 100.000000°E');
    });

    it('should handle zero longitude (prime meridian)', () => {
      expect(formatCoordinateWithDirection(50, 0)).toBe('50.000000°N, 0.000000°E');
    });

    it('should handle both zero coordinates', () => {
      expect(formatCoordinateWithDirection(0, 0)).toBe('0.000000°N, 0.000000°E');
    });
  });

  describe('formatForGPS', () => {
    it('should format coordinates in decimal degrees format', () => {
      expect(formatForGPS(40.7128, -74.0060)).toBe('40.712800, -74.006000');
    });

    it('should preserve negative signs', () => {
      expect(formatForGPS(-33.8688, -46.6333)).toBe('-33.868800, -46.633300');
    });

    it('should format positive coordinates', () => {
      expect(formatForGPS(51.5074, 0.1278)).toBe('51.507400, 0.127800');
    });

    it('should handle zero values', () => {
      expect(formatForGPS(0, 0)).toBe('0.000000, 0.000000');
    });

    it('should format with 6 decimal precision', () => {
      expect(formatForGPS(40.71280123, -74.00600987)).toBe('40.712801, -74.006010');
    });
  });

  describe('isValidLatitude', () => {
    it('should return true for valid latitudes', () => {
      expect(isValidLatitude(0)).toBe(true);
      expect(isValidLatitude(45)).toBe(true);
      expect(isValidLatitude(-45)).toBe(true);
      expect(isValidLatitude(90)).toBe(true);
      expect(isValidLatitude(-90)).toBe(true);
    });

    it('should return false for latitudes above 90', () => {
      expect(isValidLatitude(90.1)).toBe(false);
      expect(isValidLatitude(100)).toBe(false);
      expect(isValidLatitude(180)).toBe(false);
    });

    it('should return false for latitudes below -90', () => {
      expect(isValidLatitude(-90.1)).toBe(false);
      expect(isValidLatitude(-100)).toBe(false);
      expect(isValidLatitude(-180)).toBe(false);
    });

    it('should return false for NaN', () => {
      expect(isValidLatitude(NaN)).toBe(false);
    });

    it('should handle boundary values correctly', () => {
      expect(isValidLatitude(90)).toBe(true);
      expect(isValidLatitude(-90)).toBe(true);
      expect(isValidLatitude(90.0000001)).toBe(false);
      expect(isValidLatitude(-90.0000001)).toBe(false);
    });
  });

  describe('isValidLongitude', () => {
    it('should return true for valid longitudes', () => {
      expect(isValidLongitude(0)).toBe(true);
      expect(isValidLongitude(90)).toBe(true);
      expect(isValidLongitude(-90)).toBe(true);
      expect(isValidLongitude(180)).toBe(true);
      expect(isValidLongitude(-180)).toBe(true);
    });

    it('should return false for longitudes above 180', () => {
      expect(isValidLongitude(180.1)).toBe(false);
      expect(isValidLongitude(200)).toBe(false);
      expect(isValidLongitude(360)).toBe(false);
    });

    it('should return false for longitudes below -180', () => {
      expect(isValidLongitude(-180.1)).toBe(false);
      expect(isValidLongitude(-200)).toBe(false);
      expect(isValidLongitude(-360)).toBe(false);
    });

    it('should return false for NaN', () => {
      expect(isValidLongitude(NaN)).toBe(false);
    });

    it('should handle boundary values correctly', () => {
      expect(isValidLongitude(180)).toBe(true);
      expect(isValidLongitude(-180)).toBe(true);
      expect(isValidLongitude(180.0000001)).toBe(false);
      expect(isValidLongitude(-180.0000001)).toBe(false);
    });
  });
});
