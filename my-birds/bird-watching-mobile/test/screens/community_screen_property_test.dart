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
import 'community_screen_property_test.mocks.dart';

/// Property-based test generators for community screen testing
class CommunityPropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random species name
  static String generateSpeciesName() {
    final species = [
      'American Robin', 'Blue Jay', 'Cardinal', 'Sparrow', 'Eagle',
      'Hawk', 'Owl', 'Woodpecker', 'Hummingbird', 'Finch',
      'Warbler', 'Thrush', 'Chickadee', 'Nuthatch', 'Wren'
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
  
  /// Generate random coordinates
  static Map<String, double> generateCoordinates() {
    return {
      'latitude': -90 + _random.nextDouble() * 180,
      'longitude': -180 + _random.nextDouble() * 360,
    };
  }
  
  /// Generate random observation with specified shared status
  static Observation generateObservation({
    String? id,
    String? userId,
    required bool isShared,
  }) {
    final coords = generateCoordinates();
    return Observation(
      id: id ?? _random.nextInt(1000000).toString(),
      userId: userId ?? 'user_${_random.nextInt(10000)}',
      tripId: _random.nextBool() ? _random.nextInt(1000).toString() : null,
      speciesName: generateSpeciesName(),
      observationDate: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      location: generateLocation(),
      latitude: coords['latitude'],
      longitude: coords['longitude'],
      notes: _random.nextBool() ? 'Test observation notes' : null,
      photoUrl: _random.nextBool() ? 'https://example.com/photo.jpg' : null,
      localPhotoPath: null,
      isShared: isShared,
      pendingSync: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Generate a list of observations with mixed shared status
  static List<Observation> generateMixedObservations(int count) {
    final observations = <Observation>[];
    for (int i = 0; i < count; i++) {
      // Randomly make some shared and some not shared
      final isShared = _random.nextBool();
      observations.add(generateObservation(
        id: i.toString(),
        isShared: isShared,
      ));
    }
    return observations;
  }
}

void main() {
  group('CommunityScreen Property Tests', () {
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

    /// **Feature: flutter-mobile-app, Property 20: Shared observations filter**
    /// **Validates: Requirements 10.1**
    /// 
    /// Property: For any query for shared observations, the results should
    /// contain all and only observations where is_shared is true.
    test('Property 20: Shared observations filter - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of observations (10-50)
        final totalCount = 10 + Random().nextInt(41);
        final allObservations = CommunityPropertyGenerators.generateMixedObservations(totalCount);
        
        // Filter to get only shared observations
        final sharedObservations = allObservations
            .where((obs) => obs.isShared)
            .toList();
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockLocalDb);
        reset(mockConnectivity);
        
        // Mock online state (shared observations require online access)
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock API response for shared observations
        when(mockApiService.get(
          any,
          queryParams: anyNamed('queryParams'),
        )).thenAnswer((invocation) {
          final queryParams = invocation.namedArguments[const Symbol('queryParams')] as Map<String, dynamic>?;
          
          // Verify that the API is called with shared=true parameter
          expect(queryParams, isNotNull,
            reason: 'Iteration $i: Query params should be provided');
          expect(queryParams!['shared'], equals('true'),
            reason: 'Iteration $i: Should query with shared=true parameter');
          
          // Simulate pagination - return only up to page_size items
          final pageSize = int.parse(queryParams['page_size'] ?? '20');
          final paginatedObservations = sharedObservations.take(pageSize).toList();
          
          return Future.value(Response(
            requestOptions: RequestOptions(path: '/observations'),
            statusCode: 200,
            data: paginatedObservations.map((obs) => obs.toJson()).toList(),
          ));
        });
        
        // Execute getSharedObservations
        final result = await observationRepository.getSharedObservations(
          page: 1,
          pageSize: 20,
        );
        
        // Verify all returned observations have isShared = true
        for (final observation in result) {
          expect(observation.isShared, isTrue,
            reason: 'Iteration $i: All returned observations should have isShared=true');
        }
        
        // Verify no non-shared observations are included
        final nonSharedIds = allObservations
            .where((obs) => !obs.isShared)
            .map((obs) => obs.id)
            .toSet();
        
        for (final observation in result) {
          expect(nonSharedIds.contains(observation.id), isFalse,
            reason: 'Iteration $i: Non-shared observations should not be in results');
        }
        
        // Verify the count matches expected shared observations
        // (limited by page size of 20)
        final expectedCount = sharedObservations.length > 20 
            ? 20 
            : sharedObservations.length;
        expect(result.length, lessThanOrEqualTo(20),
          reason: 'Iteration $i: Should not exceed page size of 20');
        expect(result.length, equals(expectedCount),
          reason: 'Iteration $i: Should return correct number of shared observations (up to page size)');
        
        // Verify API was called with correct parameters
        verify(mockApiService.get(
          any,
          queryParams: argThat(
            predicate<Map<String, dynamic>>((params) {
              return params['shared'] == 'true' &&
                     params['page'] == '1' &&
                     params['page_size'] == '20';
            }),
            named: 'queryParams',
          ),
        )).called(1);
      }
    });

    /// Additional test: Verify shared observations are accessible only when online
    test('Property 20 (Edge case): Shared observations require online access - 50 iterations', () async {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockLocalDb);
        reset(mockConnectivity);
        
        // Mock offline state
        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        
        // Execute getSharedObservations and expect it to throw
        expect(
          () => observationRepository.getSharedObservations(page: 1, pageSize: 20),
          throwsA(isA<Exception>()),
          reason: 'Iteration $i: Should throw exception when offline',
        );
        
        // Verify API was not called
        verifyNever(mockApiService.get(any, queryParams: anyNamed('queryParams')));
      }
    });

    /// Additional test: Verify pagination works correctly for shared observations
    test('Property 20 (Pagination): Shared observations pagination - 50 iterations', () async {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate observations for multiple pages
        final page1Observations = List.generate(
          20,
          (index) => CommunityPropertyGenerators.generateObservation(
            id: 'page1_$index',
            isShared: true,
          ),
        );
        
        final page2Observations = List.generate(
          20,
          (index) => CommunityPropertyGenerators.generateObservation(
            id: 'page2_$index',
            isShared: true,
          ),
        );
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockLocalDb);
        reset(mockConnectivity);
        
        // Mock online state
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock API responses for different pages
        when(mockApiService.get(
          any,
          queryParams: argThat(
            predicate<Map<String, dynamic>>((params) => params['page'] == '1'),
            named: 'queryParams',
          ),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 200,
          data: page1Observations.map((obs) => obs.toJson()).toList(),
        ));
        
        when(mockApiService.get(
          any,
          queryParams: argThat(
            predicate<Map<String, dynamic>>((params) => params['page'] == '2'),
            named: 'queryParams',
          ),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 200,
          data: page2Observations.map((obs) => obs.toJson()).toList(),
        ));
        
        // Execute getSharedObservations for page 1
        final page1Result = await observationRepository.getSharedObservations(
          page: 1,
          pageSize: 20,
        );
        
        // Execute getSharedObservations for page 2
        final page2Result = await observationRepository.getSharedObservations(
          page: 2,
          pageSize: 20,
        );
        
        // Verify page 1 results
        expect(page1Result.length, equals(20),
          reason: 'Iteration $i: Page 1 should return 20 observations');
        expect(page1Result.every((obs) => obs.isShared), isTrue,
          reason: 'Iteration $i: All page 1 observations should be shared');
        
        // Verify page 2 results
        expect(page2Result.length, equals(20),
          reason: 'Iteration $i: Page 2 should return 20 observations');
        expect(page2Result.every((obs) => obs.isShared), isTrue,
          reason: 'Iteration $i: All page 2 observations should be shared');
        
        // Verify pages don't overlap
        final page1Ids = page1Result.map((obs) => obs.id).toSet();
        final page2Ids = page2Result.map((obs) => obs.id).toSet();
        expect(page1Ids.intersection(page2Ids).isEmpty, isTrue,
          reason: 'Iteration $i: Pages should not contain duplicate observations');
      }
    });
  });
}
