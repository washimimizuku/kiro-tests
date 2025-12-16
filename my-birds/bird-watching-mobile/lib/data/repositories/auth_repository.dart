import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Response model for login API call
class LoginResponse {
  final User user;
  final String token;

  const LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}

/// Repository for authentication operations
/// Handles login, registration, logout, and token management
class AuthRepository {
  final ApiService _apiService;
  final SecureStorage _secureStorage;

  AuthRepository({
    required ApiService apiService,
    required SecureStorage secureStorage,
  })  : _apiService = apiService,
        _secureStorage = secureStorage;

  /// Login with username and password
  /// Returns LoginResponse containing user data and authentication token
  /// Stores token securely for subsequent requests
  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        AppConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(response.data);
      
      // Store token and user info securely
      await storeToken(loginResponse.token);
      await _secureStorage.storeUserId(loginResponse.user.id);
      await _secureStorage.storeUsername(loginResponse.user.username);
      
      // Set token in API service for subsequent requests
      _apiService.setAuthToken(loginResponse.token);

      return loginResponse;
    } on DioException catch (e) {
      throw _handleApiError(e, 'Login failed');
    }
  }

  /// Register a new user account
  /// Returns User object for the newly created account
  /// Automatically logs in the user after successful registration
  Future<User> register(String username, String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConstants.registerEndpoint,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      final token = response.data['token'] as String;
      
      // Store token and user info securely
      await storeToken(token);
      await _secureStorage.storeUserId(user.id);
      await _secureStorage.storeUsername(user.username);
      
      // Set token in API service for subsequent requests
      _apiService.setAuthToken(token);

      return user;
    } on DioException catch (e) {
      throw _handleApiError(e, 'Registration failed');
    }
  }

  /// Logout the current user
  /// Clears all stored credentials and authentication tokens
  Future<void> logout() async {
    try {
      // Clear token from API service
      _apiService.clearAuthToken();
      
      // Clear all authentication data from secure storage
      await clearToken();
      await _secureStorage.clearAuthData();
      
      print('[AuthRepository] User logged out successfully');
    } catch (e) {
      print('[AuthRepository Error] Logout failed: $e');
      rethrow;
    }
  }

  /// Store authentication token securely
  Future<void> storeToken(String token) async {
    await _secureStorage.storeAuthToken(token);
  }

  /// Retrieve stored authentication token
  Future<String?> getStoredToken() async {
    return await _secureStorage.getAuthToken();
  }

  /// Clear stored authentication token
  Future<void> clearToken() async {
    await _secureStorage.deleteAuthToken();
  }

  /// Get current user information
  /// Returns null if no user is logged in
  Future<User?> getCurrentUser() async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        return null;
      }

      // Set token in API service
      _apiService.setAuthToken(token);

      // Fetch current user from API
      final response = await _apiService.get('/auth/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      // If token is invalid, clear it
      if (e.response?.statusCode == 401) {
        await logout();
      }
      return null;
    } catch (e) {
      print('[AuthRepository Error] Failed to get current user: $e');
      return null;
    }
  }

  /// Handle API errors and convert to user-friendly messages
  Exception _handleApiError(DioException error, String defaultMessage) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      // Extract error message from response
      String message = defaultMessage;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        message = data['error'] as String;
      } else if (data is Map<String, dynamic> && data.containsKey('message')) {
        message = data['message'] as String;
      }

      switch (statusCode) {
        case 400:
          return Exception('Invalid request: $message');
        case 401:
          return Exception('Invalid credentials');
        case 403:
          return Exception('Access denied');
        case 409:
          return Exception('Username or email already exists');
        case 422:
          return Exception('Validation error: $message');
        case 500:
          return Exception('Server error. Please try again later.');
        default:
          return Exception(message);
      }
    }

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception('No internet connection. Please check your network.');
    }

    return Exception(defaultMessage);
  }
}
