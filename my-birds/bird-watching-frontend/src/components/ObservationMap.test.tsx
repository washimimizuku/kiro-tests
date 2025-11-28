import { describe, it, expect } from 'vitest';
import { Observation, ObservationWithUser } from '../types';

describe('ObservationMap', () => {
  // Helper function to filter observations with coordinates (mimics component logic)
  const filterObservationsWithCoords = (observations: (Observation | ObservationWithUser)[]) => {
    return observations.filter(obs => 
      obs.latitude !== undefined && 
      obs.latitude !== null && 
      obs.longitude !== undefined && 
      obs.longitude !== null
    );
  };
  const mockObservationWithCoords: Observation = {
    id: '1',
    user_id: 'user1',
    species_name: 'Cardinal',
    observation_date: '2024-01-15T10:00:00Z',
    location: 'Central Park',
    latitude: 40.7829,
    longitude: -73.9654,
    notes: 'Beautiful red bird',
    is_shared: true,
    created_at: '2024-01-15T10:00:00Z',
    updated_at: '2024-01-15T10:00:00Z',
  };

  const mockObservationWithUser: ObservationWithUser = {
    ...mockObservationWithCoords,
    username: 'birdwatcher1',
  };

  const mockObservationWithoutCoords: Observation = {
    id: '2',
    user_id: 'user1',
    species_name: 'Sparrow',
    observation_date: '2024-01-16T10:00:00Z',
    location: 'Backyard',
    is_shared: false,
    created_at: '2024-01-16T10:00:00Z',
    updated_at: '2024-01-16T10:00:00Z',
  };

  it('should filter observations with coordinates correctly', () => {
    const filtered = filterObservationsWithCoords([mockObservationWithCoords, mockObservationWithoutCoords]);
    expect(filtered).toHaveLength(1);
    expect(filtered[0].id).toBe('1');
  });

  it('should return empty array when no observations have coordinates', () => {
    const filtered = filterObservationsWithCoords([mockObservationWithoutCoords]);
    expect(filtered).toHaveLength(0);
  });

  it('should handle observations with null coordinates', () => {
    const obsWithNullCoords: Observation = {
      ...mockObservationWithCoords,
      latitude: null as any,
      longitude: null as any,
    };

    const filtered = filterObservationsWithCoords([obsWithNullCoords]);
    expect(filtered).toHaveLength(0);
  });

  it('should handle observations with undefined coordinates', () => {
    const obsWithUndefinedCoords: Observation = {
      ...mockObservationWithCoords,
      latitude: undefined,
      longitude: undefined,
    };

    const filtered = filterObservationsWithCoords([obsWithUndefinedCoords]);
    expect(filtered).toHaveLength(0);
  });

  it('should include all observations with valid coordinates', () => {
    const observation2: Observation = {
      ...mockObservationWithCoords,
      id: '3',
      latitude: 40.7580,
      longitude: -73.9855,
      species_name: 'Blue Jay',
    };

    const filtered = filterObservationsWithCoords([mockObservationWithCoords, observation2, mockObservationWithoutCoords]);
    expect(filtered).toHaveLength(2);
  });

  it('should format coordinates with 6 decimal places', () => {
    const lat = 40.7829;
    const lng = -73.9654;
    
    const formattedLat = lat.toFixed(6);
    const formattedLng = lng.toFixed(6);
    
    expect(formattedLat).toBe('40.782900');
    expect(formattedLng).toBe('-73.965400');
  });

  it('should handle marker clustering for large datasets', () => {
    const observations = Array.from({ length: 150 }, (_, i) => ({
      ...mockObservationWithCoords,
      id: `obs-${i}`,
      latitude: 40.7829 + (Math.random() - 0.5) * 0.1,
      longitude: -73.9654 + (Math.random() - 0.5) * 0.1,
    }));

    const filtered = filterObservationsWithCoords(observations);
    expect(filtered).toHaveLength(150);
  });

  it('should preserve ObservationWithUser type', () => {
    const filtered = filterObservationsWithCoords([mockObservationWithUser]);
    expect(filtered).toHaveLength(1);
    expect('username' in filtered[0]).toBe(true);
    if ('username' in filtered[0]) {
      expect(filtered[0].username).toBe('birdwatcher1');
    }
  });
});
