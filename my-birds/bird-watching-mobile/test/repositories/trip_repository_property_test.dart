import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'package:bird_watching_mobile/data/repositories/trip_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/local_database.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/models/trip.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';

@GenerateMocks([ApiService, LocalDatabase, ConnectivityService])
import 'trip_repository_property_test.mocks.dart';

/// Property-based test generators for trip testing
class TripPropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random trip name
  static String generateTripName() {
    final names = [
      'Morning Birding', 'Weekend Trip', 'Forest Walk', 'Lake Visit',
      'Mountain Hike', 'Coastal Expedition', 'Park Survey', 'Nature Trail'
    ];
    return names[_random.nextInt(names.length)];
  }
  
  /// Generate random location
  static String generateLocation() {
    final locations = [
      'Central Park', 'Forest Trail', 'Lake Shore', 'Mountain Peak',
      'River Valley', 'Coastal Area', 'Urban Garden', 'Wildlife Reserve'
    ];
    return locations[_random.nextInt(locations.length)];
  }
  
  /// Generate random trip
  static Trip generateTrip({String? id, String? userId}) {
    return Trip(
      id: id ?? _random.nextInt(1000000).toString(),
      userId: userId ?? _random.nextInt(10000).toString(),
      name: generateTripName(),
      tripDate: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      location: generateLocation(),
      description: _random.nextBool() ? 'Test trip description' : null,
      observationCount: _random.nextInt(20),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Generate random observation
  static Observation generateObservation({String? id, String? userId, String? tripId}) {
    return Observation(
      id: id ?? _random.nextInt(1000000).toString(),
      userId: userId ?? _random.nextInt(10000).toString(),
      tripId: tripId,
      speciesName: 'Test Species ${_random.nextInt(100)}',
      observationDate: DateTime.now(),
      location: generateLocation(),
      latitude: -90 + _random.nextDouble() * 180,
      longitude: -180 + _random.nextDouble() * 360,
      notes: 'Test notes',
      photoUrl: null,
      localPhotoPath: null,
      isShared: false,
      pendingSync: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

void main() {
  group('TripRepository Property Tests', () {
    late MockApiService mockApiService;
    late MockLocalDatabase mockLocalDb;
    late MockConnectivityService mockConnectivity;
    late TripRepository tripRepository;

    setUp(() {
      mockApiService = MockApiService();
      mockLocalDb = MockLocalDatabase();
      mockConnectivity = MockConnectivityService();
      tripRepository = TripRepository(
        apiService: mockApiService,
        localDb: mockLocalDb,
        connectivity: mockConnectivity,
      );
    });

    /// **Feature: flutter-mobile-app, Property 17: Trip creation persistence**
    /// **Validates: Requirements 9.2**
    /// 
    /// Property: For any valid trip data, creating a trip should result in
    /// the trip being stored and retrievable.
    test('Property 17: Trip creation persistence - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random trip
        final trip = TripPropertyGenerators.generateTrip();
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockLocalDb);
        reset(mockConnectivity);
        
        // Mock online state
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock API response for creation
        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 201,
          data: trip.toJson(),
        ));
        
        // Mock API response for retrieval
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${trip.id}'),
          statusCode: 200,
          data: trip.toJson(),
        ));
        
        // Mock local database operations
        when(mockLocalDb.insertTrip(any)).thenAnswer((_) async => {});
        when(mockLocalDb.getTripById(trip.id))
            .thenAnswer((_) async => trip.toMap());
        
        // Execute create trip
        final result = await tripRepository.createTrip(trip);
        
        // Verify trip was stored locally
        verify(mockLocalDb.insertTrip(any)).called(1);
        
        // Verify trip is retrievable
        final retrieved = await tripRepository.getTripById(trip.id);
        
        expect(retrieved, isNotNull,
          reason: 'Iteration $i: Created trip should be retrievable');
        expect(retrieved!.id, equals(trip.id),
          reason: 'Iteration $i: Retrieved trip should have same ID');
        expect(retrieved.name, equals(trip.name),
          reason: 'Iteration $i: Retrieved trip should have same name');
        expect(retrieved.location, equals(trip.location),
          reason: 'Iteration $i: Retrieved trip should have same location');
      }
    });

    /// **Feature: flutter-mobile-app, Property 18: Trip-observation association**
    /// **Validates: Requirements 9.3, 9.4**
    /// 
    /// Property: For any trip and observation owned by the same user,
    /// associating the observation with the trip should result in the
    /// observation appearing in the trip's observation list.
    test('Property 18: Trip-observation association - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random trip and observation with same user
        final userId = Random().nextInt(10000).toString();
        final trip = TripPropertyGenerators.generateTrip(userId: userId);
        final observation = TripPropertyGenerators.generateObservation(
          userId: userId,
          tripId: null, // Initially not associated
        );
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockLocalDb);
        reset(mockConnectivity);
        
        // Mock online state
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock API response for association
        when(mockApiService.post(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${trip.id}/observations/${observation.id}'),
          statusCode: 200,
          data: {'success': true},
        ));
        
        // Mock local database operations
        when(mockLocalDb.getObservationById(observation.id))
            .thenAnswer((_) async => observation.toMap());
        when(mockLocalDb.updateObservation(any)).thenAnswer((_) async => {});
        
        // Execute association
        await tripRepository.addObservationToTrip(trip.id, observation.id);
        
        // Verify observation was updated with trip ID
        final captured = verify(mockLocalDb.updateObservation(captureAny)).captured;
        expect(captured.length, equals(1),
          reason: 'Iteration $i: Should update observation once');
        
        final updatedMap = captured[0] as Map<String, dynamic>;
        expect(updatedMap['trip_id'], equals(trip.id),
          reason: 'Iteration $i: Observation should be associated with trip');
      }
    });

    /// **Feature: flutter-mobile-app, Property 19: Trip deletion preserves observations**
    /// **Validates: Requirements 9.5**
    /// 
    /// Property: For any trip with associated observations, deleting the trip
    /// should remove the trip but preserve all observations.
    test('Property 19: Trip deletion preserves observations - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random trip with observations
        final userId = Random().nextInt(10000).toString();
        final trip = TripPropertyGenerators.generateTrip(userId: userId);
        
        // Generate 1-5 observations for this trip
        final observationCount = 1 + Random().nextInt(5);
        final observations = List.generate(
          observationCount,
          (_) => TripPropertyGenerators.generateObservation(
            userId: userId,
            tripId: trip.id,
          ),
        );
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockLocalDb);
        reset(mockConnectivity);
        
        // Mock online state
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock API response for deletion
        when(mockApiService.delete(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${trip.id}'),
          statusCode: 204,
          data: null,
        ));
        
        // Mock local database operations
        when(mockLocalDb.deleteTrip(trip.id)).thenAnswer((_) async => {});
        
        // Execute trip deletion
        await tripRepository.deleteTrip(trip.id);
        
        // Verify trip was deleted
        verify(mockLocalDb.deleteTrip(trip.id)).called(1);
        
        // Verify observations were NOT deleted
        // (deleteObservation should never be called)
        verifyNever(mockLocalDb.deleteObservation(any));
        
        // This validates that the repository preserves observations
        // when deleting a trip
      }
    });
  });
}
