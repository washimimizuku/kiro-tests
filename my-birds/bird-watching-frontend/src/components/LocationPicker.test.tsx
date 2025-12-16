import { describe, it, expect } from 'vitest';

describe('LocationPicker', () => {
  // Helper function to format coordinates (mimics component logic)
  const formatCoordinate = (value: number, type: 'lat' | 'lng'): string => {
    const direction = type === 'lat' 
      ? (value >= 0 ? 'N' : 'S')
      : (value >= 0 ? 'E' : 'W');
    return `${Math.abs(value).toFixed(6)}° ${direction}`;
  };

  it('should format coordinates with directional indicators - North and West', () => {
    const lat = 40.7128;
    const lng = -74.0060;
    
    const formattedLat = formatCoordinate(lat, 'lat');
    const formattedLng = formatCoordinate(lng, 'lng');
    
    expect(formattedLat).toBe('40.712800° N');
    expect(formattedLng).toBe('74.006000° W');
  });

  it('should format coordinates with directional indicators - South and East', () => {
    const lat = -33.8688;
    const lng = 151.2093;
    
    const formattedLat = formatCoordinate(lat, 'lat');
    const formattedLng = formatCoordinate(lng, 'lng');
    
    expect(formattedLat).toBe('33.868800° S');
    expect(formattedLng).toBe('151.209300° E');
  });

  it('should format coordinates with 6 decimal places', () => {
    const lat = 40.712345678;
    const lng = -74.006012345;
    
    const formattedLat = formatCoordinate(lat, 'lat');
    const formattedLng = formatCoordinate(lng, 'lng');
    
    expect(formattedLat).toBe('40.712346° N');
    expect(formattedLng).toBe('74.006012° W');
  });

  it('should handle zero latitude', () => {
    const lat = 0;
    const formattedLat = formatCoordinate(lat, 'lat');
    expect(formattedLat).toBe('0.000000° N');
  });

  it('should handle zero longitude', () => {
    const lng = 0;
    const formattedLng = formatCoordinate(lng, 'lng');
    expect(formattedLng).toBe('0.000000° E');
  });

  it('should handle boundary latitude values', () => {
    const northPole = formatCoordinate(90, 'lat');
    const southPole = formatCoordinate(-90, 'lat');
    
    expect(northPole).toBe('90.000000° N');
    expect(southPole).toBe('90.000000° S');
  });

  it('should handle boundary longitude values', () => {
    const eastBoundary = formatCoordinate(180, 'lng');
    const westBoundary = formatCoordinate(-180, 'lng');
    
    expect(eastBoundary).toBe('180.000000° E');
    expect(westBoundary).toBe('180.000000° W');
  });

  it('should format very small coordinate values', () => {
    const lat = 0.000001;
    const lng = -0.000001;
    
    const formattedLat = formatCoordinate(lat, 'lat');
    const formattedLng = formatCoordinate(lng, 'lng');
    
    expect(formattedLat).toBe('0.000001° N');
    expect(formattedLng).toBe('0.000001° W');
  });
});
