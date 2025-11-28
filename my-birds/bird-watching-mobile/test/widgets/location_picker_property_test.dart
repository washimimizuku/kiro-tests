import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'package:bird_watching_mobile/data/repositories/observation_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/local_database.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';

@GenerateMocks([ApiService, LocalDatabase, ConnectivityService])
import 'location_picker_property_test.mocks.dart';

/// Property-based test generators for GPS coordinates testing
class GpsCoordinatePropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random valid latitude (-90 to 90)
  static double generateLatitude() {
    return -90 + _random.nextDouble() * 180;
  }
  
  /// Generate random valid longitude (-180 to 180)
  static double generateLongitude() {
    return -180 + _random.nextDouble() * 360;
  }
  
  /// Generate random species name
  static String generateSpeciesName() {
    final species = [
      'American Robin', 'Blue Jay', 'Cardinal', 'Sparrow', 'Eagle',
      'Hawk', 'Owl', 'Woodpecker', 'Hummingbird', 'Finch',
    ];
    return species[_random.nextInt(species.length)];
  }
  
  /// Generate random location
  static String generateLocation() {
    final locations = [
      'Central Park', 'Forest Trail', 'Lake Shore', 'Mountain Peak',
      'River Valley', 'Coastal Area', 'Urban Garden', 'Wildlife Reserve'
    ];
    return locations[_random.nextInt(locations.length)];
  }
  
  /// Generate random observation with GPS coordinates
  static Observation generateObservationWithGps({
    String? id,
    String? userId,
    double? latitude,
    double? longitude,
  }) {
    return Observation(
      id: id ?? _random.nextInt(1000000).toString(),
      userId: userId ?? _random.nextInt(10000).toString(),
      tripId: null,
      speciesName: generateSpeciesName(),
      observationDate: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      location: generateLocation(),
      latitude: latitude ?? generateLatitude(),
      longitude: longitude ?? generateLongitude(),
      notes: 'Test observation with GPS coordinates',
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
  group('LocationPicker Property Tests', () {
    late MockApiService mockApiService;
    late MockLocalDatabase mockLocalDb;
    late MockConnectivityService mockConnectivity;
    late ObservationRepository observationRepository;

    setUp(() {
      mockApiService = MockApiService();
      mockLocalDb = MockLocalDatabase();
      mockConnectivity = MockConnectivityService();
      observationRepository = ObservationRepository(
        apiService: mockApiService,
        localDb: mockLocalDb,
        connectivity: mockConnectivity,
      );
    });

    /// **Feature: flutter-mobile-app, Property 7: GPS coordinates storage**
    /// **Validates: Requirements 4.2**
    /// 
    /// Property: For any observation created with GPS coordinates,
    /// the latitude and longitude should be stored and retrievable.
    test('Property 7: GPS coordinates storage - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random GPS coordinates
        final latitude = GpsCoordinatePropertyGenerators.generateLatitude();
        final longitude = GpsCoordinatePropertyGenerators.generateLongitude();
        
        // Generate observation with these coordinates
        final observation = GpsCoordinatePropertyGenerators.generateObservationWithGps(
          latitude: latitude,
          longitude: longitude,
        );
        
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
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 201,
          data: observation.toJson(),
        ));
        
        // Mock API response for retrieval
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations/${observation.id}'),
          statusCode: 200,
          data: observation.toJson(),
        ));
        
        // Mock local database operations
        when(mockLocalDb.insertObservation(any)).thenAnswer((_) async => {});
        when(mockLocalDb.getObservationById(observation.id))
            .thenAnswer((_) async => observation.toMap());
        
        // Execute create observation
        final result = await observationRepository.createObservation(observation);
        
        // Verify GPS coordinates are stored
        expect(result.latitude, isNotNull,
          reason: 'Iteration $i: Latitude should be stored');
        expect(result.longitude, isNotNull,
          reason: 'Iteration $i: Longitude should be stored');
        
        // Verify stored coordinates match input
        expect(result.latitude, equals(latitude),
          reason: 'Iteration $i: Stored latitude should match input (${latitude})');
        expect(result.longitude, equals(longitude),
          reason: 'Iteration $i: Stored longitude should match input (${longitude})');
        
        // Verify coordinates are within valid ranges
        expect(result.latitude! >= -90 && result.latitude! <= 90, isTrue,
          reason: 'Iteration $i: Latitude should be in valid range [-90, 90]');
        expect(result.longitude! >= -180 && result.longitude! <= 180, isTrue,
          reason: 'Iteration $i: Longitude should be in valid range [-180, 180]');
        
        // Verify observation is retrievable with coordinates
        final retrieved = await observationRepository.getObservationById(observation.id);
        
        expect(retrieved, isNotNull,
          reason: 'Iteration $i: Created observation should be retrievable');
        expect(retrieved!.latitude, equals(latitude),
          reason: 'Iteration $i: Retrieved latitude should match stored value');
        expect(retrieved.longitude, equals(longitude),
          reason: 'Iteration $i: Retrieved longitude should match stored value');
        
        // Verify local database was called with correct coordinates
        // Note: insertObservation is called twice - once after create, once after retrieve
        final captured = verify(mockLocalDb.insertObservation(captureAny)).captured;
        expect(captured.length, greaterThanOrEqualTo(1),
          reason: 'Iteration $i: Should capture at least one observation map');
        
        // Check the first captured call (from create)
        final capturedMap = captured[0] as Map<String, dynamic>;
        expect(capturedMap['latitude'], equals(latitude),
          reason: 'Iteration $i: Database should receive correct latitude');
        expect(capturedMap['longitude'], equals(longitude),
          reason: 'Iteration $i: Database should receive correct longitude');
      }
    });
  });
}
