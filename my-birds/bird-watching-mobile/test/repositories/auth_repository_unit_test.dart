import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:bird_watching_mobile/data/repositories/auth_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/secure_storage.dart';
import 'package:bird_watching_mobile/data/models/user.dart';

@GenerateMocks([ApiService, SecureStorage])
import 'auth_repository_unit_test.mocks.dart';

void main() {
  group('AuthRepository Unit Tests', () {
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

    group('login', () {
      test('should successfully login with valid credentials', () async {
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

        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
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

        // Act
        final result = await authRepository.login(username, password);

        // Assert
        expect(result.user.username, equals(username));
        expect(result.token, equals(token));
        verify(mockSecureStorage.storeAuthToken(token)).called(1);
        verify(mockSecureStorage.storeUserId(user.id)).called(1);
        verify(mockSecureStorage.storeUsername(username)).called(1);
        verify(mockApiService.setAuthToken(token)).called(1);
      });

      test('should throw exception on invalid credentials', () async {
        // Arrange
        const username = 'testuser';
        const password = 'wrongpass';

        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 401,
              data: {'error': 'Invalid credentials'},
            ),
          ),
        );

        // Act & Assert
        expect(
          () => authRepository.login(username, password),
          throwsA(isA<DioException>()),
        );
        verifyNever(mockSecureStorage.storeAuthToken(any));
        verifyNever(mockApiService.setAuthToken(any));
      });

      test('should handle network error during login', () async {
        // Arrange
        const username = 'testuser';
        const password = 'testpass123';

        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.connectionTimeout,
            error: 'Connection timeout',
          ),
        );

        // Act & Assert
        expect(
          () => authRepository.login(username, password),
          throwsA(isA<DioException>()),
        );
        verifyNever(mockSecureStorage.storeAuthToken(any));
      });
    });

    group('register', () {
      test('should successfully register new user', () async {
        // Arrange
        const username = 'newuser';
        const email = 'new@example.com';
        const password = 'newpass123';
        const token = 'new_token_12345';
        final user = User(
          id: '2',
          username: username,
          email: email,
          createdAt: DateTime.now(),
        );

        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 201,
          data: {
            'user': user.toJson(),
            'token': token,
          },
        ));

        when(mockSecureStorage.storeAuthToken(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.storeUserId(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.storeUsername(any)).thenAnswer((_) async => {});

        // Act
        final result = await authRepository.register(username, email, password);

        // Assert
        expect(result.username, equals(username));
        expect(result.email, equals(email));
        verify(mockSecureStorage.storeAuthToken(token)).called(1);
        verify(mockApiService.setAuthToken(token)).called(1);
      });

      test('should throw exception on duplicate username', () async {
        // Arrange
        const username = 'existinguser';
        const email = 'new@example.com';
        const password = 'newpass123';

        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/register'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/register'),
              statusCode: 409,
              data: {'error': 'Username already exists'},
            ),
          ),
        );

        // Act & Assert
        expect(
          () => authRepository.register(username, email, password),
          throwsA(isA<DioException>()),
        );
        verifyNever(mockSecureStorage.storeAuthToken(any));
      });

      test('should throw exception on invalid email format', () async {
        // Arrange
        const username = 'newuser';
        const email = 'invalid-email';
        const password = 'newpass123';

        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/register'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/register'),
              statusCode: 400,
              data: {'error': 'Invalid email format'},
            ),
          ),
        );

        // Act & Assert
        expect(
          () => authRepository.register(username, email, password),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('logout', () {
      test('should clear all stored credentials', () async {
        // Arrange
        when(mockSecureStorage.deleteAuthToken()).thenAnswer((_) async => {});
        when(mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

        // Act
        await authRepository.logout();

        // Assert
        verify(mockSecureStorage.deleteAuthToken()).called(1);
        verify(mockSecureStorage.clearAuthData()).called(1);
        verify(mockApiService.clearAuthToken()).called(1);
      });

      test('should handle error during logout gracefully', () async {
        // Arrange
        when(mockSecureStorage.deleteAuthToken())
            .thenThrow(Exception('Storage error'));
        when(mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => authRepository.logout(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getStoredToken', () {
      test('should return stored token when available', () async {
        // Arrange
        const token = 'stored_token_12345';
        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => token);

        // Act
        final result = await authRepository.getStoredToken();

        // Assert
        expect(result, equals(token));
        verify(mockSecureStorage.getAuthToken()).called(1);
      });

      test('should return null when no token stored', () async {
        // Arrange
        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => null);

        // Act
        final result = await authRepository.getStoredToken();

        // Assert
        expect(result, isNull);
      });
    });

    group('getCurrentUser', () {
      test('should return current user when authenticated', () async {
        // Arrange
        const userId = '1';
        const username = 'testuser';
        const token = 'test_token';
        final user = User(
          id: userId,
          username: username,
          email: 'test@example.com',
          createdAt: DateTime.now(),
        );

        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => token);
        when(mockSecureStorage.getUserId()).thenAnswer((_) async => userId);
        when(mockApiService.get(any)).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/users/$userId'),
          statusCode: 200,
          data: user.toJson(),
        ));

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(userId));
        expect(result.username, equals(username));
      });

      test('should return null when not authenticated', () async {
        // Arrange
        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => null);

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, isNull);
        verifyNever(mockApiService.get(any));
      });
    });
  });
}
