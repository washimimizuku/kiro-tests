import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:bird_watching_mobile/data/repositories/observation_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/local_database.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';

@GenerateMocks([ApiService, LocalDatabase, ConnectivityService])
import 'observation_repository_unit_test.mocks.dart';

void main() {
  group('ObservationRepository Unit Tests', () {
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

    final testObservation = Observation(
      id: '1',
      userId: 'user1',
      tripId: null,
      speciesName: 'American Robin',
      observationDate: DateTime(2024, 1, 15),
      location: 'Central Park',
      latitude: 40.7829,
      longitude: -73.9654,
      notes: 'Beautiful bird',
      photoUrl: 'https://example.com/photo.jpg',
      localPhotoPath: null,
      isShared: true,
      pendingSync: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    group('getObservations - Online', () {
      test('should fetch observations from API when online', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 200,
          data: [testObservation.toJson()],
        ));
        when(mockLocalDb.insertObservation(any)).thenAnswer((_) async => {});

        // Act
        final result = await observationRepository.getObservations();

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals(testObservation.id));
        verify(mockApiService.get(any)).called(1);
        verify(mockLocalDb.insertObservation(any)).called(1);
      });

      test('should cache observations locally after fetching', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 200,
          data: [testObservation.toJson()],
        ));
        when(mockLocalDb.insertObservation(any)).thenAnswer((_) async => {});

        // Act
        await observationRepository.getObservations();

        // Assert
        verify(mockLocalDb.insertObservation(any)).called(1);
      });
    });

    group('getObservations - Offline', () {
      test('should fetch observations from local database when offline', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        when(mockLocalDb.getObservations())
            .thenAnswer((_) async => [testObservation.toMap()]);

        // Act
        final result = await observationRepository.getObservations();

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals(testObservation.id));
        verify(mockLocalDb.getObservations()).called(1);
        verifyNever(mockApiService.get(any));
      });

      test('should return empty list when offline and no local data', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        when(mockLocalDb.getObservations()).thenAnswer((_) async => []);

        // Act
        final result = await observationRepository.getObservations();

        // Assert
        expect(result, isEmpty);
        verify(mockLocalDb.getObservations()).called(1);
      });
    });

    group('createObservation - Online', () {
      test('should create observation via API when online', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 201,
          data: testObservation.toJson(),
        ));
        when(mockLocalDb.insertObservation(any)).thenAnswer((_) async => {});

        // Act
        final result = await observationRepository.createObservation(testObservation);

        // Assert
        expect(result.id, equals(testObservation.id));
        expect(result.pendingSync, isFalse);
        verify(mockApiService.post(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDb.insertObservation(any)).called(1);
      });

      test('should handle API error and store locally with pending sync', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/observations'),
          type: DioExceptionType.connectionTimeout,
        ));
        when(mockLocalDb.insertObservation(any, pendingSync: anyNamed('pendingSync')))
            .thenAnswer((_) async => {});

        // Act
        final result = await observationRepository.createObservation(testObservation);

        // Assert
        expect(result.pendingSync, isTrue);
        verify(mockLocalDb.insertObservation(any, pendingSync: true)).called(1);
      });
    });

    group('createObservation - Offline', () {
      test('should store observation locally with pending sync when offline', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        when(mockLocalDb.insertObservation(any, pendingSync: anyNamed('pendingSync')))
            .thenAnswer((_) async => {});

        // Act
        final result = await observationRepository.createObservation(testObservation);

        // Assert
        expect(result.pendingSync, isTrue);
        verify(mockLocalDb.insertObservation(any, pendingSync: true)).called(1);
        verifyNever(mockApiService.post(any, data: anyNamed('data')));
      });
    });

    group('updateObservation', () {
      test('should update observation via API when online', () async {
        // Arrange
        final updatedObservation = testObservation.copyWith(
          speciesName: 'Blue Jay',
          notes: 'Updated notes',
        );

        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.put(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations/${testObservation.id}'),
          statusCode: 200,
          data: updatedObservation.toJson(),
        ));
        when(mockLocalDb.updateObservation(any)).thenAnswer((_) async => {});

        // Act
        final result = await observationRepository.updateObservation(updatedObservation);

        // Assert
        expect(result.speciesName, equals('Blue Jay'));
        expect(result.notes, equals('Updated notes'));
        verify(mockApiService.put(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDb.updateObservation(any)).called(1);
      });

      test('should store update locally with pending sync when offline', () async {
        // Arrange
        final updatedObservation = testObservation.copyWith(
          speciesName: 'Blue Jay',
        );

        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        when(mockLocalDb.updateObservation(any)).thenAnswer((_) async => {});

        // Act
        final result = await observationRepository.updateObservation(updatedObservation);

        // Assert
        expect(result.pendingSync, isTrue);
        verify(mockLocalDb.updateObservation(any)).called(1);
        verifyNever(mockApiService.put(any, data: anyNamed('data')));
      });
    });

    group('deleteObservation', () {
      test('should delete observation via API when online', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.delete(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations/${testObservation.id}'),
          statusCode: 204,
        ));
        when(mockLocalDb.deleteObservation(any)).thenAnswer((_) async => {});

        // Act
        await observationRepository.deleteObservation(testObservation.id);

        // Assert
        verify(mockApiService.delete(any)).called(1);
        verify(mockLocalDb.deleteObservation(testObservation.id)).called(1);
      });

      test('should handle API error during deletion', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.delete(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/observations/${testObservation.id}'),
          response: Response(
            requestOptions: RequestOptions(path: '/observations/${testObservation.id}'),
            statusCode: 404,
            data: {'error': 'Not found'},
          ),
        ));

        // Act & Assert
        expect(
          () => observationRepository.deleteObservation(testObservation.id),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getPendingSyncObservations', () {
      test('should return observations with pending sync status', () async {
        // Arrange
        final pendingObservation = testObservation.copyWith(pendingSync: true);
        when(mockLocalDb.getPendingSyncObservations())
            .thenAnswer((_) async => [pendingObservation.toMap()]);

        // Act
        final result = await observationRepository.getPendingSyncObservations();

        // Assert
        expect(result.length, equals(1));
        expect(result.first.pendingSync, isTrue);
        verify(mockLocalDb.getPendingSyncObservations()).called(1);
      });

      test('should return empty list when no pending syncs', () async {
        // Arrange
        when(mockLocalDb.getPendingSyncObservations())
            .thenAnswer((_) async => []);

        // Act
        final result = await observationRepository.getPendingSyncObservations();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('syncObservation', () {
      test('should sync observation and mark as synced', () async {
        // Arrange
        final pendingObservation = testObservation.copyWith(pendingSync: true);
        when(mockApiService.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 201,
          data: testObservation.toJson(),
        ));
        when(mockLocalDb.markAsSynced(any)).thenAnswer((_) async => {});

        // Act
        await observationRepository.syncObservation(pendingObservation);

        // Assert
        verify(mockApiService.post(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDb.markAsSynced(pendingObservation.id)).called(1);
      });

      test('should throw exception on sync failure', () async {
        // Arrange
        final pendingObservation = testObservation.copyWith(pendingSync: true);
        when(mockApiService.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/observations'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => observationRepository.syncObservation(pendingObservation),
          throwsA(isA<DioException>()),
        );
        verifyNever(mockLocalDb.markAsSynced(any));
      });
    });

    group('searchObservations', () {
      test('should search observations by species name', () async {
        // Arrange
        const query = 'Robin';
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/observations'),
          statusCode: 200,
          data: [testObservation.toJson()],
        ));

        // Act
        final result = await observationRepository.searchObservations(query);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.speciesName.toLowerCase(), contains(query.toLowerCase()));
      });

      test('should search locally when offline', () async {
        // Arrange
        const query = 'Robin';
        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        when(mockLocalDb.getObservations())
            .thenAnswer((_) async => [testObservation.toMap()]);

        // Act
        final result = await observationRepository.searchObservations(query);

        // Assert
        expect(result.length, equals(1));
        verify(mockLocalDb.getObservations()).called(1);
        verifyNever(mockApiService.get(any));
      });
    });

    group('Error Handling', () {
      test('should handle network timeout gracefully', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/observations'),
          type: DioExceptionType.connectionTimeout,
          error: 'Connection timeout',
        ));
        when(mockLocalDb.getObservations())
            .thenAnswer((_) async => [testObservation.toMap()]);

        // Act
        final result = await observationRepository.getObservations();

        // Assert
        expect(result.length, equals(1));
        verify(mockLocalDb.getObservations()).called(1);
      });

      test('should handle server error and fallback to local data', () async {
        // Arrange
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        when(mockApiService.get(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/observations'),
          response: Response(
            requestOptions: RequestOptions(path: '/observations'),
            statusCode: 500,
            data: {'error': 'Internal server error'},
          ),
        ));
        when(mockLocalDb.getObservations())
            .thenAnswer((_) async => [testObservation.toMap()]);

        // Act
        final result = await observationRepository.getObservations();

        // Assert
        expect(result.length, equals(1));
        verify(mockLocalDb.getObservations()).called(1);
      });
    });
  });
}
