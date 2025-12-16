import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'package:bird_watching_mobile/data/repositories/auth_repository.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';
import 'package:bird_watching_mobile/data/services/secure_storage.dart';
import 'package:bird_watching_mobile/data/models/user.dart';

@GenerateMocks([ApiService, SecureStorage])
import 'auth_repository_property_test.mocks.dart';

/// Property-based test generators for authentication testing
class AuthPropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random valid username
  static String generateUsername() {
    final length = 5 + _random.nextInt(20); // 5-25 characters
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789_';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }
  
  /// Generate random valid password
  static String generatePassword() {
    final length = 8 + _random.nextInt(20); // 8-28 characters
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }
  
  /// Generate random valid email
  static String generateEmail() {
    final username = generateUsername();
    final domains = ['example.com', 'test.com', 'mail.com', 'email.com'];
    return '$username@${domains[_random.nextInt(domains.length)]}';
  }
  
  /// Generate random authentication token
  static String generateToken() {
    final length = 32 + _random.nextInt(32); // 32-64 characters
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }
  
  /// Generate random user ID
  static String generateUserId() {
    return _random.nextInt(1000000).toString();
  }
  
  /// Generate random User object
  static User generateUser() {
    return User(
      id: generateUserId(),
      username: generateUsername(),
      email: generateEmail(),
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
    );
  }
}

void main() {
  group('AuthRepository Property Tests', () {
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

    /// **Feature: flutter-mobile-app, Property 1: Valid login stores token**
    /// **Validates: Requirements 1.2**
    /// 
    /// Property: For any valid username and password combination, 
    /// successful authentication should result in a token being securely 
    /// stored and retrievable.
    test('Property 1: Valid login stores token - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random valid credentials
        final username = AuthPropertyGenerators.generateUsername();
        final password = AuthPropertyGenerators.generatePassword();
        final token = AuthPropertyGenerators.generateToken();
        final user = AuthPropertyGenerators.generateUser();
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockSecureStorage);
        
        // Mock successful login response
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
        
        // Mock secure storage operations
        when(mockSecureStorage.storeAuthToken(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.storeUserId(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.storeUsername(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => token);
        
        // Execute login
        final result = await authRepository.login(username, password);
        
        // Verify token was stored
        verify(mockSecureStorage.storeAuthToken(token)).called(1);
        
        // Verify token is retrievable
        final storedToken = await authRepository.getStoredToken();
        expect(storedToken, equals(token), 
          reason: 'Iteration $i: Token should be retrievable after login');
        
        // Verify user data is correct
        expect(result.user.id, equals(user.id));
        expect(result.user.username, equals(user.username));
        expect(result.user.email, equals(user.email));
        expect(result.token, equals(token));
        
        // Verify API service has token set
        verify(mockApiService.setAuthToken(token)).called(1);
      }
    });

    /// **Feature: flutter-mobile-app, Property 2: Logout clears credentials**
    /// **Validates: Requirements 1.5, 13.5, 20.5**
    /// 
    /// Property: For any authenticated user, logging out should remove all 
    /// stored authentication tokens and credentials from secure storage.
    test('Property 2: Logout clears credentials - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random token
        final token = AuthPropertyGenerators.generateToken();
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockSecureStorage);
        
        // Mock secure storage operations
        when(mockSecureStorage.deleteAuthToken()).thenAnswer((_) async => {});
        when(mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});
        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => null);
        
        // Execute logout
        await authRepository.logout();
        
        // Verify token was deleted
        verify(mockSecureStorage.deleteAuthToken()).called(1);
        
        // Verify all auth data was cleared
        verify(mockSecureStorage.clearAuthData()).called(1);
        
        // Verify API service token was cleared
        verify(mockApiService.clearAuthToken()).called(1);
        
        // Verify token is no longer retrievable
        final storedToken = await authRepository.getStoredToken();
        expect(storedToken, isNull, 
          reason: 'Iteration $i: Token should be null after logout');
      }
    });

    /// **Feature: flutter-mobile-app, Property 3: Registration creates account**
    /// **Validates: Requirements 2.2, 2.3**
    /// 
    /// Property: For any valid registration data (unique username, valid email, password),
    /// registration should create a new user account and automatically authenticate the user.
    test('Property 3: Registration creates account - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random valid registration data
        final username = AuthPropertyGenerators.generateUsername();
        final email = AuthPropertyGenerators.generateEmail();
        final password = AuthPropertyGenerators.generatePassword();
        final token = AuthPropertyGenerators.generateToken();
        final userId = AuthPropertyGenerators.generateUserId();
        
        final user = User(
          id: userId,
          username: username,
          email: email,
          createdAt: DateTime.now(),
        );
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockSecureStorage);
        
        // Mock successful registration response
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
        
        // Mock secure storage operations
        when(mockSecureStorage.storeAuthToken(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.storeUserId(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.storeUsername(any)).thenAnswer((_) async => {});
        when(mockSecureStorage.getAuthToken()).thenAnswer((_) async => token);
        
        // Execute registration
        final result = await authRepository.register(username, email, password);
        
        // Verify user was created with correct data
        expect(result.username, equals(username));
        expect(result.email, equals(email));
        
        // Verify token was stored (auto-login)
        verify(mockSecureStorage.storeAuthToken(token)).called(1);
        verify(mockSecureStorage.storeUserId(userId)).called(1);
        verify(mockSecureStorage.storeUsername(username)).called(1);
        
        // Verify API service has token set (auto-login)
        verify(mockApiService.setAuthToken(token)).called(1);
        
        // Verify token is retrievable
        final storedToken = await authRepository.getStoredToken();
        expect(storedToken, equals(token), 
          reason: 'Iteration $i: Token should be retrievable after registration');
      }
    });

    /// **Feature: flutter-mobile-app, Property 4: Duplicate registration rejection**
    /// **Validates: Requirements 2.4**
    /// 
    /// Property: For any registration attempt with an existing username or email,
    /// the system should reject the registration with an appropriate error.
    test('Property 4: Duplicate registration rejection - 100 iterations', () async {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random registration data
        final username = AuthPropertyGenerators.generateUsername();
        final email = AuthPropertyGenerators.generateEmail();
        final password = AuthPropertyGenerators.generatePassword();
        
        // Reset mocks for each iteration
        reset(mockApiService);
        reset(mockSecureStorage);
        
        // Mock duplicate registration error (409 Conflict)
        when(mockApiService.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/register'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/register'),
              statusCode: 409,
              data: {
                'error': 'Username or email already exists',
              },
            ),
          ),
        );
        
        // Execute registration and expect error
        try {
          await authRepository.register(username, email, password);
          fail('Iteration $i: Should have thrown exception for duplicate registration');
        } catch (e) {
          // Verify error message indicates duplicate
          expect(e.toString(), contains('already exists'),
            reason: 'Iteration $i: Error should indicate duplicate username/email');
        }
        
        // Verify no token was stored
        verifyNever(mockSecureStorage.storeAuthToken(any));
        verifyNever(mockSecureStorage.storeUserId(any));
        verifyNever(mockSecureStorage.storeUsername(any));
        
        // Verify API service token was not set
        verifyNever(mockApiService.setAuthToken(any));
      }
    });
  });
}
