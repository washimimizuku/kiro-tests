import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

/// Service for handling HTTP API requests with authentication and error handling
class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService({Dio? dio}) {
    _dio = dio ?? Dio();
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add request interceptor for logging and auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          
          // Log request
          print('[API Request] ${options.method} ${options.path}');
          if (options.queryParameters.isNotEmpty) {
            print('[API Query] ${options.queryParameters}');
          }
          if (options.data != null) {
            print('[API Body] ${options.data}');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          print('[API Response] ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          // Log error
          print('[API Error] ${error.requestOptions.path}');
          print('[API Error Details] ${error.message}');
          if (error.response != null) {
            print('[API Error Response] ${error.response?.statusCode} ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token for subsequent requests
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Perform GET request with retry logic
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    return _retryRequest(() => _dio.get(
          path,
          queryParameters: queryParams,
          options: options,
        ));
  }

  /// Perform POST request with retry logic
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    return _retryRequest(() => _dio.post(
          path,
          data: data,
          queryParameters: queryParams,
          options: options,
        ));
  }

  /// Perform PUT request with retry logic
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    return _retryRequest(() => _dio.put(
          path,
          data: data,
          queryParameters: queryParams,
          options: options,
        ));
  }

  /// Perform DELETE request with retry logic
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    return _retryRequest(() => _dio.delete(
          path,
          data: data,
          queryParameters: queryParams,
          options: options,
        ));
  }

  /// Upload file with multipart form data
  Future<Response> uploadFile(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      ...?additionalData,
    });

    return _retryRequest(() => _dio.post(
          path,
          data: formData,
          options: Options(
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
          onSendProgress: onSendProgress,
        ));
  }

  /// Retry logic with exponential backoff
  Future<Response> _retryRequest(
    Future<Response> Function() request, {
    int maxAttempts = AppConstants.maxRetryAttempts,
  }) async {
    int attempt = 0;
    Duration delay = AppConstants.retryDelay;

    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        attempt++;

        // Don't retry on client errors (4xx) or if max attempts reached
        if (attempt >= maxAttempts || _isClientError(e)) {
          rethrow;
        }

        // Only retry on network errors or server errors (5xx)
        if (!_shouldRetry(e)) {
          rethrow;
        }

        print('[API Retry] Attempt $attempt/$maxAttempts after ${delay.inSeconds}s');
        await Future.delayed(delay);

        // Exponential backoff
        delay *= 2;
      }
    }
  }

  /// Check if error is a client error (4xx)
  bool _isClientError(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode != null && statusCode >= 400 && statusCode < 500;
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException error) {
    // Retry on network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on server errors (5xx)
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    return false;
  }

  /// Close the Dio client
  void close() {
    _dio.close();
  }
}
