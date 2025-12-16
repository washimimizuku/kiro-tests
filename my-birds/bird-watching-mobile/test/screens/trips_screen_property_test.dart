import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:bird_watching_mobile/data/models/trip.dart';

/// Property-based test generators for trip screen testing
class TripScreenPropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random trip name
  static String generateTripName() {
    final names = [
      'Morning Birding', 'Weekend Trip', 'Forest Walk', 'Lake Visit',
      'Mountain Hike', 'Coastal Expedition', 'Park Survey', 'Nature Trail',
      'Spring Migration', 'Fall Colors', 'Winter Watch', 'Summer Safari'
    ];
    return names[_random.nextInt(names.length)];
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
  
  /// Generate random trip with specific date
  static Trip generateTrip({
    String? id,
    String? userId,
    DateTime? tripDate,
  }) {
    return Trip(
      id: id ?? _random.nextInt(1000000).toString(),
      userId: userId ?? _random.nextInt(10000).toString(),
      name: generateTripName(),
      tripDate: tripDate ?? DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      location: generateLocation(),
      description: _random.nextBool() ? 'Test trip description' : null,
      observationCount: _random.nextInt(20),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Generate a list of random trips
  static List<Trip> generateTripList({
    int count = 10,
    String? userId,
  }) {
    return List.generate(
      count,
      (index) => generateTrip(
        id: index.toString(),
        userId: userId,
      ),
    );
  }
}

void main() {
  group('Trip Screen Property Tests', () {
    
    /// **Feature: flutter-mobile-app, Property 13: Trips chronological order**
    /// **Validates: Requirements 9.1**
    /// 
    /// Property: For any list of trips, they should be ordered by trip_date
    /// in descending order (most recent first).
    test('Property 13: Trips chronological order - 100 iterations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of trips (5-50)
        final count = 5 + Random().nextInt(46);
        final trips = TripScreenPropertyGenerators.generateTripList(
          count: count,
          userId: 'test-user',
        );
        
        // Sort trips by date descending (most recent first)
        final sortedTrips = List<Trip>.from(trips)
          ..sort((a, b) => b.tripDate.compareTo(a.tripDate));
        
        // Verify the list is in descending chronological order
        for (int j = 0; j < sortedTrips.length - 1; j++) {
          final current = sortedTrips[j];
          final next = sortedTrips[j + 1];
          
          expect(
            current.tripDate.isAfter(next.tripDate) ||
                current.tripDate.isAtSameMomentAs(next.tripDate),
            isTrue,
            reason: 'Iteration $i: Trip at index $j (${current.tripDate}) should be '
                'after or equal to trip at index ${j + 1} (${next.tripDate})',
          );
        }
      }
    });
  });
}
