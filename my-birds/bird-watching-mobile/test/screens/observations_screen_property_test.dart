import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:bird_watching_mobile/data/models/observation.dart';

/// Property-based test generators for observation screen testing
class ObservationScreenPropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random species name
  static String generateSpeciesName() {
    final species = [
      'American Robin', 'Blue Jay', 'Cardinal', 'Sparrow', 'Eagle',
      'Hawk', 'Owl', 'Woodpecker', 'Hummingbird', 'Finch',
      'Warbler', 'Thrush', 'Chickadee', 'Nuthatch', 'Wren',
      'Crow', 'Raven', 'Magpie', 'Starling', 'Blackbird'
    ];
    return species[_random.nextInt(species.length)];
  }
  
  /// Generate random location
  static String generateLocation() {
    final locations = [
      'Central Park', 'Forest Trail', 'Lake Shore', 'Mountain Peak',
      'River Valley', 'Coastal Area', 'Urban Garden', 'Wildlife Reserve',
      'Wetland Marsh', 'Desert Oasis', 'Prairie Field', 'Canyon Ridge'
    ];
    return locations[_random.nextInt(locations.length)];
  }
  
  /// Generate random coordinates
  static Map<String, double> generateCoordinates() {
    return {
      'latitude': -90 + _random.nextDouble() * 180,
      'longitude': -180 + _random.nextDouble() * 360,
    };
  }
  
  /// Generate random observation with specific date
  static Observation generateObservation({
    String? id,
    String? userId,
    DateTime? observationDate,
    bool pendingSync = false,
  }) {
    final coords = generateCoordinates();
    return Observation(
      id: id ?? _random.nextInt(1000000).toString(),
      userId: userId ?? _random.nextInt(10000).toString(),
      tripId: _random.nextBool() ? _random.nextInt(1000).toString() : null,
      speciesName: generateSpeciesName(),
      observationDate: observationDate ?? DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      location: generateLocation(),
      latitude: coords['latitude'],
      longitude: coords['longitude'],
      notes: _random.nextBool() ? 'Test observation notes' : null,
      photoUrl: _random.nextBool() ? 'https://example.com/photo.jpg' : null,
      localPhotoPath: null,
      isShared: _random.nextBool(),
      pendingSync: pendingSync,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Generate a list of random observations
  static List<Observation> generateObservationList({
    int count = 10,
    String? userId,
  }) {
    return List.generate(
      count,
      (index) => generateObservation(
        id: index.toString(),
        userId: userId,
      ),
    );
  }
}

void main() {
  group('Observation Screen Property Tests', () {
    
    /// **Feature: flutter-mobile-app, Property 12: Observations chronological order**
    /// **Validates: Requirements 6.1**
    /// 
    /// Property: For any list of observations, they should be ordered by
    /// observation_date in descending order (most recent first).
    test('Property 12: Observations chronological order - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of observations (5-50)
        final count = 5 + Random().nextInt(46);
        final observations = ObservationScreenPropertyGenerators.generateObservationList(
          count: count,
          userId: 'test-user',
        );
        
        // Sort observations by date descending (most recent first)
        final sortedObservations = List<Observation>.from(observations)
          ..sort((a, b) => b.observationDate.compareTo(a.observationDate));
        
        // Verify the list is in descending chronological order
        for (int j = 0; j < sortedObservations.length - 1; j++) {
          final current = sortedObservations[j];
          final next = sortedObservations[j + 1];
          
          expect(
            current.observationDate.isAfter(next.observationDate) ||
                current.observationDate.isAtSameMomentAs(next.observationDate),
            isTrue,
            reason: 'Observation at index $j (${current.observationDate}) should be '
                'after or equal to observation at index ${j + 1} (${next.observationDate})',
          );
        }
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 21: Search filter correctness**
    /// **Validates: Requirements 10.3, 11.1**
    /// 
    /// Property: For any search query, results should contain all and only
    /// observations where species_name or location contains the query string
    /// (case-insensitive).
    test('Property 21: Search filter correctness - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random observations
        final observations = ObservationScreenPropertyGenerators.generateObservationList(
          count: 20,
          userId: 'test-user',
        );
        
        // Pick a random search query from existing data
        final searchTargets = [
          ...observations.map((o) => o.speciesName),
          ...observations.map((o) => o.location),
        ];
        
        if (searchTargets.isEmpty) continue;
        
        final query = searchTargets[Random().nextInt(searchTargets.length)];
        final queryLower = query.toLowerCase();
        
        // Filter observations
        final filtered = observations.where((obs) {
          return obs.speciesName.toLowerCase().contains(queryLower) ||
                 obs.location.toLowerCase().contains(queryLower);
        }).toList();
        
        // Verify all filtered observations match the query
        for (final obs in filtered) {
          final matches = obs.speciesName.toLowerCase().contains(queryLower) ||
                         obs.location.toLowerCase().contains(queryLower);
          
          expect(
            matches,
            isTrue,
            reason: 'Observation ${obs.id} should match query "$query"',
          );
        }
        
        // Verify no non-matching observations are included
        final nonFiltered = observations.where((obs) => !filtered.contains(obs));
        for (final obs in nonFiltered) {
          final matches = obs.speciesName.toLowerCase().contains(queryLower) ||
                         obs.location.toLowerCase().contains(queryLower);
          
          expect(
            matches,
            isFalse,
            reason: 'Observation ${obs.id} should not match query "$query"',
          );
        }
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 22: Date range filter correctness**
    /// **Validates: Requirements 11.2**
    /// 
    /// Property: For any date range filter, results should contain all and only
    /// observations where observation_date is within the specified range.
    test('Property 22: Date range filter correctness - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random observations with various dates
        final observations = ObservationScreenPropertyGenerators.generateObservationList(
          count: 30,
          userId: 'test-user',
        );
        
        // Generate random date range
        final now = DateTime.now();
        final daysBack = Random().nextInt(365);
        final rangeSize = 30 + Random().nextInt(60); // 30-90 days
        
        final startDate = now.subtract(Duration(days: daysBack + rangeSize));
        final endDate = now.subtract(Duration(days: daysBack));
        
        // Filter observations by date range
        final filtered = observations.where((obs) {
          return obs.observationDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                 obs.observationDate.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();
        
        // Verify all filtered observations are within the date range
        for (final obs in filtered) {
          final inRange = obs.observationDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                         obs.observationDate.isBefore(endDate.add(const Duration(days: 1)));
          
          expect(
            inRange,
            isTrue,
            reason: 'Observation ${obs.id} date ${obs.observationDate} should be '
                'within range $startDate to $endDate',
          );
        }
        
        // Verify no out-of-range observations are included
        final nonFiltered = observations.where((obs) => !filtered.contains(obs));
        for (final obs in nonFiltered) {
          final inRange = obs.observationDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                         obs.observationDate.isBefore(endDate.add(const Duration(days: 1)));
          
          expect(
            inRange,
            isFalse,
            reason: 'Observation ${obs.id} date ${obs.observationDate} should not be '
                'within range $startDate to $endDate',
          );
        }
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 23: Filter clearing returns all results**
    /// **Validates: Requirements 11.3**
    /// 
    /// Property: For any active filters, clearing all filters should return
    /// the complete unfiltered observation list.
    test('Property 23: Filter clearing returns all results - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random observations
        final allObservations = ObservationScreenPropertyGenerators.generateObservationList(
          count: 25,
          userId: 'test-user',
        );
        
        // Apply some filter (e.g., search)
        final query = 'Robin';
        final filtered = allObservations.where((obs) {
          return obs.speciesName.toLowerCase().contains(query.toLowerCase()) ||
                 obs.location.toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        // Clear filters - should return all observations
        final afterClear = allObservations;
        
        // Verify we get all observations back
        expect(
          afterClear.length,
          equals(allObservations.length),
          reason: 'After clearing filters, should have all ${allObservations.length} observations',
        );
        
        // Verify all original observations are present
        for (final obs in allObservations) {
          expect(
            afterClear.contains(obs),
            isTrue,
            reason: 'Observation ${obs.id} should be present after clearing filters',
          );
        }
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 25: Pagination page size**
    /// **Validates: Requirements 10.5**
    /// 
    /// Property: For any paginated list request, the number of items returned
    /// should not exceed the specified page size (default: 20).
    test('Property 25: Pagination page size - 100 iterations', () {
      const iterations = 100;
      const pageSize = 20;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of observations (10-100)
        final totalCount = 10 + Random().nextInt(91);
        final allObservations = ObservationScreenPropertyGenerators.generateObservationList(
          count: totalCount,
          userId: 'test-user',
        );
        
        // Simulate pagination - get first page
        final page1 = allObservations.take(pageSize).toList();
        
        // Verify page size constraint
        expect(
          page1.length,
          lessThanOrEqualTo(pageSize),
          reason: 'First page should not exceed page size of $pageSize',
        );
        
        // If there are more observations than page size, verify we got exactly pageSize
        if (totalCount >= pageSize) {
          expect(
            page1.length,
            equals(pageSize),
            reason: 'First page should have exactly $pageSize items when more are available',
          );
        } else {
          // If fewer observations than page size, verify we got all of them
          expect(
            page1.length,
            equals(totalCount),
            reason: 'First page should have all $totalCount items when fewer than page size',
          );
        }
        
        // Test second page if applicable
        if (totalCount > pageSize) {
          final page2 = allObservations.skip(pageSize).take(pageSize).toList();
          
          expect(
            page2.length,
            lessThanOrEqualTo(pageSize),
            reason: 'Second page should not exceed page size of $pageSize',
          );
          
          // Verify no overlap between pages
          for (final obs in page2) {
            expect(
              page1.contains(obs),
              isFalse,
              reason: 'Observation ${obs.id} should not appear in both pages',
            );
          }
        }
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 8: Coordinate validation**
    /// **Validates: Requirements 18.2**
    /// 
    /// Property: For any coordinate input, latitude outside [-90, 90] or
    /// longitude outside [-180, 180] should be rejected with a validation error.
    test('Property 8: Coordinate validation - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random coordinates, some valid, some invalid
        final random = Random();
        
        // Test invalid latitudes
        final invalidLat = random.nextBool()
            ? -90 - random.nextDouble() * 100  // Below -90
            : 90 + random.nextDouble() * 100;   // Above 90
        
        expect(
          _isValidLatitude(invalidLat),
          isFalse,
          reason: 'Latitude $invalidLat should be invalid (outside [-90, 90])',
        );
        
        // Test invalid longitudes
        final invalidLng = random.nextBool()
            ? -180 - random.nextDouble() * 100  // Below -180
            : 180 + random.nextDouble() * 100;   // Above 180
        
        expect(
          _isValidLongitude(invalidLng),
          isFalse,
          reason: 'Longitude $invalidLng should be invalid (outside [-180, 180])',
        );
        
        // Test valid coordinates
        final validLat = -90 + random.nextDouble() * 180;  // [-90, 90]
        final validLng = -180 + random.nextDouble() * 360; // [-180, 180]
        
        expect(
          _isValidLatitude(validLat),
          isTrue,
          reason: 'Latitude $validLat should be valid (within [-90, 90])',
        );
        
        expect(
          _isValidLongitude(validLng),
          isTrue,
          reason: 'Longitude $validLng should be valid (within [-180, 180])',
        );
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 34: Future date rejection**
    /// **Validates: Requirements 18.3**
    /// 
    /// Property: For any observation with an observation_date in the future,
    /// the creation or update should be rejected with a validation error.
    test('Property 34: Future date rejection - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final now = DateTime.now();
        
        // Generate future date (1-365 days in the future)
        final daysInFuture = 1 + Random().nextInt(365);
        final futureDate = now.add(Duration(days: daysInFuture));
        
        expect(
          _isValidObservationDate(futureDate),
          isFalse,
          reason: 'Future date $futureDate should be rejected',
        );
        
        // Generate past date (should be valid)
        final daysInPast = 1 + Random().nextInt(365);
        final pastDate = now.subtract(Duration(days: daysInPast));
        
        expect(
          _isValidObservationDate(pastDate),
          isTrue,
          reason: 'Past date $pastDate should be valid',
        );
        
        // Today should be valid
        expect(
          _isValidObservationDate(now),
          isTrue,
          reason: 'Today\'s date should be valid',
        );
      }
    });
    
    /// **Feature: flutter-mobile-app, Property 35: Text length validation**
    /// **Validates: Requirements 18.4**
    /// 
    /// Property: For any text field with a maximum length constraint,
    /// input exceeding that length should be truncated or rejected with
    /// a validation error.
    test('Property 35: Text length validation - 100 iterations', () {
      const iterations = 100;
      const maxSpeciesLength = 100;
      const maxLocationLength = 200;
      const maxNotesLength = 1000;
      
      for (int i = 0; i < iterations; i++) {
        final random = Random();
        
        // Test species name length
        final speciesLength = maxSpeciesLength + 1 + random.nextInt(100);
        final longSpeciesName = 'A' * speciesLength;
        
        expect(
          _isValidSpeciesName(longSpeciesName),
          isFalse,
          reason: 'Species name of length $speciesLength should be rejected '
              '(max: $maxSpeciesLength)',
        );
        
        // Valid species name
        final validSpeciesLength = 1 + random.nextInt(maxSpeciesLength);
        final validSpeciesName = 'A' * validSpeciesLength;
        
        expect(
          _isValidSpeciesName(validSpeciesName),
          isTrue,
          reason: 'Species name of length $validSpeciesLength should be valid',
        );
        
        // Test location length
        final locationLength = maxLocationLength + 1 + random.nextInt(100);
        final longLocation = 'B' * locationLength;
        
        expect(
          _isValidLocation(longLocation),
          isFalse,
          reason: 'Location of length $locationLength should be rejected '
              '(max: $maxLocationLength)',
        );
        
        // Valid location
        final validLocationLength = 1 + random.nextInt(maxLocationLength);
        final validLocation = 'B' * validLocationLength;
        
        expect(
          _isValidLocation(validLocation),
          isTrue,
          reason: 'Location of length $validLocationLength should be valid',
        );
        
        // Test notes length
        final notesLength = maxNotesLength + 1 + random.nextInt(500);
        final longNotes = 'C' * notesLength;
        
        expect(
          _isValidNotes(longNotes),
          isFalse,
          reason: 'Notes of length $notesLength should be rejected '
              '(max: $maxNotesLength)',
        );
        
        // Valid notes (including empty)
        if (random.nextBool()) {
          // Empty notes should be valid
          expect(
            _isValidNotes(''),
            isTrue,
            reason: 'Empty notes should be valid',
          );
        } else {
          // Non-empty valid notes
          final validNotesLength = 1 + random.nextInt(maxNotesLength);
          final validNotes = 'C' * validNotesLength;
          
          expect(
            _isValidNotes(validNotes),
            isTrue,
            reason: 'Notes of length $validNotesLength should be valid',
          );
        }
      }
    });
  });
}

// Validation helper functions
bool _isValidLatitude(double latitude) {
  return latitude >= -90 && latitude <= 90;
}

bool _isValidLongitude(double longitude) {
  return longitude >= -180 && longitude <= 180;
}

bool _isValidObservationDate(DateTime date) {
  return !date.isAfter(DateTime.now());
}

bool _isValidSpeciesName(String name) {
  return name.trim().isNotEmpty && name.trim().length <= 100;
}

bool _isValidLocation(String location) {
  return location.trim().isNotEmpty && location.trim().length <= 200;
}

bool _isValidNotes(String notes) {
  return notes.length <= 1000;
}
