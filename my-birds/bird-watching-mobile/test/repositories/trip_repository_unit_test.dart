import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:bird_watching_mobile/data/repositories/trip_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/local_database.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/models/trip.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';

@GenerateMocks([ApiService, LocalDatabase, ConnectivityService])
import 'trip_repository_unit_test.mocks.dart';

void main() {
  group('TripRepository Unit Tests', () {
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

    final testTrip = Trip(
      id: '1',
      userId: 'user1',
      name: 'Spring Birding',
      tripDate: DateTime(2024, 3, 15),
      location: 'Central Park',
      description: 'Morning bird watching',
      observationCount: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('getTrips', () {
      test('should fetch trips from API', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 200,
          data: [testTrip.toJson()],
        ));
        when(mockLocalDb.insertTrip(any)).thenAnswer((_) async => {});

        // Act
        final result = await tripRepository.getTrips(forceRefresh: true);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals(testTrip.id));
        verify(mockApiService.get(any)).called(1);
        verify(mockLocalDb.insertTrip(any)).called(1);
      });

      test('should handle API error and return local trips', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/trips'),
          type: DioExceptionType.connectionTimeout,
        ));
        when(mockLocalDb.getTrips(userId: anyNamed('userId')))
            .thenAnswer((_) async => [testTrip.toMap()]);

        // Act
        final result = await tripRepository.getTrips();

        // Assert
        expect(result.length, equals(1));
        verify(mockLocalDb.getTrips()).called(1);
      });
    });

    group('getTripById', () {
      test('should fetch trip by ID from API', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}'),
          statusCode: 200,
          data: testTrip.toJson(),
        ));
        when(mockLocalDb.insertTrip(any)).thenAnswer((_) async => {});

        // Act
        final result = await tripRepository.getTripById(testTrip.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(testTrip.id));
        expect(result.name, equals(testTrip.name));
        verify(mockApiService.get(any)).called(1);
      });

      test('should return null when trip not found', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/trips/999'),
          response: Response(
            requestOptions: RequestOptions(path: '/trips/999'),
            statusCode: 404,
            data: {'error': 'Trip not found'},
          ),
        ));
        when(mockLocalDb.getTripById(any)).thenAnswer((_) async => null);

        // Act
        final result = await tripRepository.getTripById('999');

        // Assert
        expect(result, isNull);
      });
    });

    group('createTrip', () {
      test('should create trip via API', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 201,
          data: testTrip.toJson(),
        ));
        when(mockLocalDb.insertTrip(any)).thenAnswer((_) async => {});

        // Act
        final result = await tripRepository.createTrip(testTrip);

        // Assert
        expect(result.id, equals(testTrip.id));
        expect(result.name, equals(testTrip.name));
        verify(mockApiService.post(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDb.insertTrip(any)).called(1);
      });

      test('should handle validation error', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/trips'),
          response: Response(
            requestOptions: RequestOptions(path: '/trips'),
            statusCode: 400,
            data: {'error': 'Invalid trip data'},
          ),
        ));

        // Act & Assert
        expect(
          () => tripRepository.createTrip(testTrip),
          throwsA(isA<DioException>()),
        );
        verifyNever(mockLocalDb.insertTrip(any));
      });
    });

    group('updateTrip', () {
      test('should update trip via API', () async {
        // Arrange
        final updatedTrip = testTrip.copyWith(
          name: 'Updated Trip Name',
          description: 'Updated description',
        );

        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.put(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}'),
          statusCode: 200,
          data: updatedTrip.toJson(),
        ));
        when(mockLocalDb.updateTrip(any)).thenAnswer((_) async => {});

        // Act
        final result = await tripRepository.updateTrip(updatedTrip);

        // Assert
        expect(result.name, equals('Updated Trip Name'));
        expect(result.description, equals('Updated description'));
        verify(mockApiService.put(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDb.updateTrip(any)).called(1);
      });

      test('should handle unauthorized update', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.put(any, data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}'),
          response: Response(
            requestOptions: RequestOptions(path: '/trips/${testTrip.id}'),
            statusCode: 403,
            data: {'error': 'Unauthorized'},
          ),
        ));

        // Act & Assert
        expect(
          () => tripRepository.updateTrip(testTrip),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('deleteTrip', () {
      test('should delete trip via API', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.delete(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}'),
          statusCode: 204,
        ));
        when(mockLocalDb.deleteTrip(any)).thenAnswer((_) async => {});

        // Act
        await tripRepository.deleteTrip(testTrip.id);

        // Assert
        verify(mockApiService.delete(any)).called(1);
        verify(mockLocalDb.deleteTrip(testTrip.id)).called(1);
      });

      test('should handle deletion of non-existent trip', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.delete(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/trips/999'),
          response: Response(
            requestOptions: RequestOptions(path: '/trips/999'),
            statusCode: 404,
            data: {'error': 'Trip not found'},
          ),
        ));

        // Act & Assert
        expect(
          () => tripRepository.deleteTrip('999'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getTripObservations', () {
      test('should fetch observations for a trip', () async {
        // Arrange
        final observation = Observation(
          id: '1',
          userId: 'user1',
          tripId: testTrip.id,
          speciesName: 'American Robin',
          observationDate: DateTime(2024, 3, 15),
          location: 'Central Park',
          latitude: 40.7829,
          longitude: -73.9654,
          notes: null,
          photoUrl: null,
          localPhotoPath: null,
          isShared: false,
          pendingSync: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}/observations'),
          statusCode: 200,
          data: [observation.toJson()],
        ));
        when(mockLocalDb.insertObservation(any)).thenAnswer((_) async => {});

        // Act
        final result = await tripRepository.getTripObservations(testTrip.id);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.tripId, equals(testTrip.id));
        verify(mockApiService.get(any)).called(1);
      });

      test('should return empty list when trip has no observations', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}/observations'),
          statusCode: 200,
          data: [],
        ));

        // Act
        final result = await tripRepository.getTripObservations(testTrip.id);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle API error when fetching trip observations', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/trips/${testTrip.id}/observations'),
          type: DioExceptionType.connectionTimeout,
        ));
        when(mockLocalDb.getObservations(
          userId: anyNamed('userId'),
          pendingSync: anyNamed('pendingSync'),
          useCache: anyNamed('useCache'),
        )).thenAnswer((_) async => []);

        // Act
        final result = await tripRepository.getTripObservations(testTrip.id);

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
