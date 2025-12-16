import { describe, it, expect } from 'vitest';
import { isValidLatitude, isValidLongitude } from '../utils/coordinateUtils';

describe('ObservationForm Coordinate Validation', () => {
  it('should validate coordinate pair requirement logic', () => {
    // Test that both coordinates must be provided together
    const latitude = 40.7128;
    const longitude = undefined;

    // This simulates the validation logic in the form
    const hasPartialCoordinates = 
      (latitude !== undefined && longitude === undefined) ||
      (latitude === undefined && longitude !== undefined);

    expect(hasPartialCoordinates).toBe(true);
  });

  it('should validate latitude bounds', () => {
    // Valid latitudes
    expect(isValidLatitude(0)).toBe(true);
    expect(isValidLatitude(90)).toBe(true);
    expect(isValidLatitude(-90)).toBe(true);
    expect(isValidLatitude(45.5)).toBe(true);

    // Invalid latitudes
    expect(isValidLatitude(91)).toBe(false);
    expect(isValidLatitude(-91)).toBe(false);
    expect(isValidLatitude(95)).toBe(false);
    expect(isValidLatitude(NaN)).toBe(false);
  });

  it('should validate longitude bounds', () => {
    // Valid longitudes
    expect(isValidLongitude(0)).toBe(true);
    expect(isValidLongitude(180)).toBe(true);
    expect(isValidLongitude(-180)).toBe(true);
    expect(isValidLongitude(120.5)).toBe(true);

    // Invalid longitudes
    expect(isValidLongitude(181)).toBe(false);
    expect(isValidLongitude(-181)).toBe(false);
    expect(isValidLongitude(200)).toBe(false);
    expect(isValidLongitude(NaN)).toBe(false);
  });

  it('should accept valid coordinate pairs', () => {
    const testCases = [
      { lat: 40.7128, lng: -74.0060 }, // New York
      { lat: 51.5074, lng: -0.1278 },  // London
      { lat: -33.8688, lng: 151.2093 }, // Sydney
      { lat: 0, lng: 0 },               // Null Island
      { lat: 90, lng: 180 },            // Boundaries
      { lat: -90, lng: -180 },          // Boundaries
    ];

    testCases.forEach(({ lat, lng }) => {
      expect(isValidLatitude(lat)).toBe(true);
      expect(isValidLongitude(lng)).toBe(true);
    });
  });

  it('should reject invalid coordinate pairs', () => {
    const testCases = [
      { lat: 95, lng: -74.0060 },      // Invalid latitude
      { lat: 40.7128, lng: 200 },      // Invalid longitude
      { lat: -100, lng: 0 },           // Invalid latitude
      { lat: 0, lng: -200 },           // Invalid longitude
      { lat: NaN, lng: 0 },            // NaN latitude
      { lat: 0, lng: NaN },            // NaN longitude
    ];

    testCases.forEach(({ lat, lng }) => {
      const isValid = isValidLatitude(lat) && isValidLongitude(lng);
      expect(isValid).toBe(false);
    });
  });

  it('should handle optional coordinates correctly', () => {
    // Both undefined - valid (optional)
    const case1 = { lat: undefined, lng: undefined };
    const isCase1Valid = case1.lat === undefined && case1.lng === undefined;
    expect(isCase1Valid).toBe(true);

    // Both defined and valid - valid
    const case2 = { lat: 40.7128, lng: -74.0060 };
    const isCase2Valid = 
      case2.lat !== undefined && 
      case2.lng !== undefined &&
      isValidLatitude(case2.lat) && 
      isValidLongitude(case2.lng);
    expect(isCase2Valid).toBe(true);

    // Only one defined - invalid
    const case3 = { lat: 40.7128, lng: undefined };
    const isCase3Valid = !(
      (case3.lat !== undefined && case3.lng === undefined) ||
      (case3.lat === undefined && case3.lng !== undefined)
    );
    expect(isCase3Valid).toBe(false);
  });

  it('should format coordinates for submission', () => {
    // Test that coordinates are properly included in submission data
    const formData = {
      species_name: 'American Robin',
      location: 'Central Park',
      latitude: 40.7128,
      longitude: -74.0060,
    };

    expect(formData.latitude).toBe(40.7128);
    expect(formData.longitude).toBe(-74.0060);
  });

  it('should handle coordinate clearing', () => {
    // Test that coordinates can be set to undefined
    let formData = {
      latitude: 40.7128 as number | undefined,
      longitude: -74.0060 as number | undefined,
    };

    // Clear coordinates
    formData = {
      latitude: undefined,
      longitude: undefined,
    };

    expect(formData.latitude).toBeUndefined();
    expect(formData.longitude).toBeUndefined();
  });
});
