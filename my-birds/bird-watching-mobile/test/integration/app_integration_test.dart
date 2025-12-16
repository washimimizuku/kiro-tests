import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bird_watching_mobile/data/repositories/auth_repository.dart';
import 'package:bird_watching_mobile/data/repositories/observation_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/local_database.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/services/secure_storage.dart';
import 'package:bird_watching_mobile/data/models/user.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';
import 'package:dio/dio.dart';

@GenerateMocks([ApiService, LocalDatabase, ConnectivityService, SecureStorage])
import 'app_integration_test.mocks.dart';

/// Integration tests for the Bird Watching Mobile App
/// 
/// These tests verify complete user flows through the application components.
/// They test the integration between repositories, services, and data models.
void main() {
  group('Authentication Flow Integration', () {
    late MockApiService mockApiService;
    late MockSecureStorage mockSecureStorage;
    late AuthRepository authRepository;

    setUp(() {
      mockApiService = MockApiService();
      mockSecureStorage = MockSecureStorage();
      authRepository = AuthRepository(
        apiService: mockApiService,
        secureStorage: mockSecureStorage,
      );
    });

    test('complete login flow stores token and user data', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass123';
      const token = 'test_token_12345';
      final user = User(
        id: '1',
        username: username,
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      when(mockApiService.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 200,
        data: {
          'user': user.toJson(),
          'token': token,
        },
      ));

      when(mockSecureStorage.storeAuthToken(any)).thenAnswer((_) async => {});
      when(mockSecureStorage.storeUserId(any)).thenAnswer((_) async => {});
      when(mockSecureStorage.storeUsername(any)).thenAnswer((_) async => {});
      when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => token);

      // Act - Complete login flow
      final loginResult = await authRepository.login(username, password);
      final storedToken = await authRepository.getStoredToken();

      // Assert - Verify complete flow
      expect(loginResult.user.username, equals(username));
      expect(loginResult.token, equals(token));
      expect(storedToken, equals(token));
      verify(mockApiService.setAuthToken(token)).called(1);
    });

    test('complete logout flow clears all data', () async {
      // Arrange
      when(mockSecureStorage.deleteAuthToken()).thenAnswer((_) async => {});
      when(mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});
      when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => null);

      // Act - Complete logout flow
      await authRepository.logout();
      final storedToken = await authRepository.getStoredToken();

      // Assert - Verify complete flow
      expect(storedToken, isNull);
      verify(mockApiService.clearAuthToken()).called(1);
      verify(mockSecureStorage.deleteAuthToken()).called(1);
      verify(mockSecureStorage.clearAuthData()).called(1);
    });
  });

  group('Observation CRUD Flow Integration', () {
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

    test('complete observation creation flow (online)', () async {
      // Arrange
      final observation = Observation(
        id: '1',
        userId: 'user1',
        tripId: null,
        speciesName: 'American Robin',
        observationDate: DateTime(2024, 1, 15),
        location: 'Central Park',
        latitude: 40.7829,
        longitude: -73.9654,
        notes: 'Beautiful bird',
        photoUrl: null,
        localPhotoPath: null,
        isShared: true,
        pendingSync: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
      when(mockApiService.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/observations'),
        statusCode: 201,
        data: observation.toJson(),
      ));
      when(mockLocalDb.insertObservation(any)).thenAnswer((_) async => {});

      // Act - Complete creation flow
      final result = await observationRepository.createObservation(observation);

      // Assert - Verify complete flow
      expect(result.id, equals(observation.id));
      expect(result.pendingSync, isFalse);
      verify(mockApiService.post(any, data: anyNamed('data'))).called(1);
      verify(mockLocalDb.insertObservation(any)).called(1);
    });

    test('complete observation creation flow (offline)', () async {
      // Arrange
      final observation = Observation(
        id: '1',
        userId: 'user1',
        tripId: null,
        speciesName: 'American Robin',
        observationDate: DateTime(2024, 1, 15),
        location: 'Central Park',
        latitude: 40.7829,
        longitude: -73.9654,
        notes: 'Beautiful bird',
        photoUrl: null,
        localPhotoPath: null,
        isShared: true,
        pendingSync: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
      when(mockLocalDb.insertObservation(any, pendingSync: anyNamed('pendingSync')))
          .thenAnswer((_) async => {});

      // Act - Complete offline creation flow
      final result = await observationRepository.createObservation(observation);

      // Assert - Verify complete flow
      expect(result.pendingSync, isTrue);
      verify(mockLocalDb.insertObservation(any, pendingSync: true)).called(1);
      verifyNever(mockApiService.post(any, data: anyNamed('data')));
    });
  });

  group('Sync Flow Integration', () {
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

    test('retrieves pending sync observations', () async {
      // Arrange
      final pendingObservation = Observation(
        id: '1',
        userId: 'user1',
        tripId: null,
        speciesName: 'American Robin',
        observationDate: DateTime(2024, 1, 15),
        location: 'Central Park',
        latitude: 40.7829,
        longitude: -73.9654,
        notes: 'Beautiful bird',
        photoUrl: null,
        localPhotoPath: null,
        isShared: true,
        pendingSync: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockLocalDb.getPendingSyncObservations())
          .thenAnswer((_) async => [pendingObservation.toMap()]);

      // Act - Get pending observations
      final pendingObs = await observationRepository.getPendingSyncObservations();

      // Assert - Verify flow
      expect(pendingObs.length, equals(1));
      expect(pendingObs.first.pendingSync, isTrue);
      expect(pendingObs.first.id, equals(pendingObservation.id));
    });
  });
}
