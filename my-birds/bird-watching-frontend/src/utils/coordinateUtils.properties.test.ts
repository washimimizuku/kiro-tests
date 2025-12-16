import { describe, it, expect } from 'vitest';
import * as fc from 'fast-check';
import {
  filterObservationsWithCoordinates,
  filterSharedObservationsWithCoordinates,
  filterTripObservationsWithCoordinates,
} from './coordinateUtils';

// Generators for property-based testing
const validLatitude = () => fc.double({ min: -90, max: 90 });
const validLongitude = () => fc.double({ min: -180, max: 180 });

const observationWithCoords = () =>
  fc.record({
    id: fc.uuid(),
    latitude: validLatitude(),
    longitude: validLongitude(),
    is_shared: fc.boolean(),
    trip_id: fc.option(fc.uuid(), { nil: undefined }),
  });

const observationWithoutCoords = () =>
  fc.record({
    id: fc.uuid(),
    latitude: fc.constantFrom(undefined, null),
    longitude: fc.constantFrom(undefined, null),
    is_shared: fc.boolean(),
    trip_id: fc.option(fc.uuid(), { nil: undefined }),
  });

const observationWithPartialCoords = () =>
  fc.record({
    id: fc.uuid(),
    latitude: fc.oneof(validLatitude(), fc.constantFrom(undefined, null)),
    longitude: fc.constantFrom(undefined, null),
    is_shared: fc.boolean(),
    trip_id: fc.option(fc.uuid(), { nil: undefined }),
  });

const mixedObservations = () =>
  fc.array(
    fc.oneof(
      observationWithCoords(),
      observationWithoutCoords(),
      observationWithPartialCoords()
    ),
    { minLength: 0, maxLength: 50 }
  );

describe('coordinateUtils - Property-Based Tests', () => {
  describe('Property 11: Coordinate filtering for map display', () => {
    // Feature: geolocation-map-view, Property 11: Coordinate filtering for map display
    // Validates: Requirements 3.3
    it('should only include observations with both latitude and longitude', () => {
      fc.assert(
        fc.property(mixedObservations(), (observations) => {
          const filtered = filterObservationsWithCoordinates(observations);
          
          // All filtered observations must have both coordinates
          filtered.forEach(obs => {
            expect(obs.latitude).toBeDefined();
            expect(obs.latitude).not.toBeNull();
            expect(obs.longitude).toBeDefined();
            expect(obs.longitude).not.toBeNull();
          });
          
          // No observation with missing coordinates should be in the result
          const withoutCoords = observations.filter(
            obs => obs.latitude === undefined || 
                   obs.latitude === null || 
                   obs.longitude === undefined || 
                   obs.longitude === null
          );
          withoutCoords.forEach(obs => {
            expect(filtered).not.toContainEqual(obs);
          });
        }),
        { numRuns: 100 }
      );
    });

    it('should preserve all observations that have both coordinates', () => {
      fc.assert(
        fc.property(fc.array(observationWithCoords(), { minLength: 1, maxLength: 20 }), (observations) => {
          const filtered = filterObservationsWithCoordinates(observations);
          
          // All observations with coordinates should be in the result
          expect(filtered.length).toBe(observations.length);
          observations.forEach(obs => {
            expect(filtered).toContainEqual(obs);
          });
        }),
        { numRuns: 100 }
      );
    });

    it('should return empty array when no observations have coordinates', () => {
      fc.assert(
        fc.property(fc.array(observationWithoutCoords(), { minLength: 1, maxLength: 20 }), (observations) => {
          const filtered = filterObservationsWithCoordinates(observations);
          expect(filtered).toEqual([]);
        }),
        { numRuns: 100 }
      );
    });
  });

  describe('Property 12: Shared observations with coordinates', () => {
    // Feature: geolocation-map-view, Property 12: Shared observations with coordinates
    // Validates: Requirements 5.1, 5.3
    it('should only include observations that are shared AND have coordinates', () => {
      fc.assert(
        fc.property(mixedObservations(), (observations) => {
          const filtered = filterSharedObservationsWithCoordinates(observations);
          
          // All filtered observations must be shared and have both coordinates
          filtered.forEach(obs => {
            expect(obs.is_shared).toBe(true);
            expect(obs.latitude).toBeDefined();
            expect(obs.latitude).not.toBeNull();
            expect(obs.longitude).toBeDefined();
            expect(obs.longitude).not.toBeNull();
          });
        }),
        { numRuns: 100 }
      );
    });

    it('should exclude non-shared observations even if they have coordinates', () => {
      fc.assert(
        fc.property(
          fc.array(
            fc.record({
              id: fc.uuid(),
              latitude: validLatitude(),
              longitude: validLongitude(),
              is_shared: fc.constant(false),
              trip_id: fc.option(fc.uuid(), { nil: undefined }),
            }),
            { minLength: 1, maxLength: 20 }
          ),
          (observations) => {
            const filtered = filterSharedObservationsWithCoordinates(observations);
            expect(filtered).toEqual([]);
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should exclude shared observations without coordinates', () => {
      fc.assert(
        fc.property(
          fc.array(
            fc.record({
              id: fc.uuid(),
              latitude: fc.constantFrom(undefined, null),
              longitude: fc.constantFrom(undefined, null),
              is_shared: fc.constant(true),
              trip_id: fc.option(fc.uuid(), { nil: undefined }),
            }),
            { minLength: 1, maxLength: 20 }
          ),
          (observations) => {
            const filtered = filterSharedObservationsWithCoordinates(observations);
            expect(filtered).toEqual([]);
          }
        ),
        { numRuns: 100 }
      );
    });
  });

  describe('Property 13: Trip observations with coordinates', () => {
    // Feature: geolocation-map-view, Property 13: Trip observations with coordinates
    // Validates: Requirements 6.1
    it('should only include observations from specified trip with coordinates', () => {
      fc.assert(
        fc.property(
          fc.uuid(),
          mixedObservations(),
          (tripId, observations) => {
            const filtered = filterTripObservationsWithCoordinates(observations, tripId);
            
            // All filtered observations must belong to the trip and have both coordinates
            filtered.forEach(obs => {
              expect(obs.trip_id).toBe(tripId);
              expect(obs.latitude).toBeDefined();
              expect(obs.latitude).not.toBeNull();
              expect(obs.longitude).toBeDefined();
              expect(obs.longitude).not.toBeNull();
            });
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should exclude observations from other trips even if they have coordinates', () => {
      fc.assert(
        fc.property(
          fc.uuid(),
          fc.uuid(),
          fc.array(observationWithCoords(), { minLength: 1, maxLength: 20 }),
          (tripId1, tripId2, observations) => {
            fc.pre(tripId1 !== tripId2); // Ensure different trip IDs
            
            // Set all observations to tripId2
            const obsWithTrip = observations.map(obs => ({ ...obs, trip_id: tripId2 }));
            
            // Filter for tripId1
            const filtered = filterTripObservationsWithCoordinates(obsWithTrip, tripId1);
            
            // Should be empty since all observations belong to tripId2
            expect(filtered).toEqual([]);
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should exclude trip observations without coordinates', () => {
      fc.assert(
        fc.property(
          fc.uuid(),
          fc.array(observationWithoutCoords(), { minLength: 1, maxLength: 20 }),
          (tripId, observations) => {
            // Set all observations to the same trip
            const obsWithTrip = observations.map(obs => ({ ...obs, trip_id: tripId }));
            
            const filtered = filterTripObservationsWithCoordinates(obsWithTrip, tripId);
            
            // Should be empty since no observations have coordinates
            expect(filtered).toEqual([]);
          }
        ),
        { numRuns: 100 }
      );
    });

    it('should preserve all trip observations that have coordinates', () => {
      fc.assert(
        fc.property(
          fc.uuid(),
          fc.array(observationWithCoords(), { minLength: 1, maxLength: 20 }),
          (tripId, observations) => {
            // Set all observations to the same trip
            const obsWithTrip = observations.map(obs => ({ ...obs, trip_id: tripId }));
            
            const filtered = filterTripObservationsWithCoordinates(obsWithTrip, tripId);
            
            // All observations should be in the result
            expect(filtered.length).toBe(obsWithTrip.length);
            obsWithTrip.forEach(obs => {
              expect(filtered).toContainEqual(obs);
            });
          }
        ),
        { numRuns: 100 }
      );
    });
  });
});
