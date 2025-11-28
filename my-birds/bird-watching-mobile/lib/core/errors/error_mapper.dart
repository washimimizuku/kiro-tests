import 'package:dio/dio.dart';
import 'app_error.dart';

/// Maps various error types to user-friendly AppError instances
class ErrorMapper {
  /// Map a generic error to an AppError
  static AppError mapError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is DioException) {
      return _mapDioError(error);
    }

    // Generic unknown error
    return UnknownError(
      message: 'An unexpected error occurred',
      details: error.toString(),
      originalError: error,
    );
  }

  /// Map Dio errors to specific AppError types
  static AppError _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: 'Connection timeout',
          details: 'The request took too long. Please check your internet connection and try again.',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'No internet connection',
          details: 'Please check your internet connection and try again.',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _mapResponseError(error);

      case DioExceptionType.cancel:
        return NetworkError(
          message: 'Request cancelled',
          details: 'The request was cancelled.',
          originalError: error,
        );

      case DioExceptionType.unknown:
        return NetworkError(
          message: 'Network error',
          details: 'Unable to connect to the server. Please try again later.',
          originalError: error,
        );

      default:
        return NetworkError(
          message: 'Network error',
          details: error.message ?? 'An unknown network error occurred.',
          originalError: error,
        );
    }
  }

  /// Map HTTP response errors to specific AppError types
  static AppError _mapResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    switch (statusCode) {
      case 400:
        return ValidationError(
          message: 'Invalid request',
          details: _extractErrorMessage(responseData) ?? 'The request contains invalid data.',
          originalError: error,
        );

      case 401:
        return AuthenticationError(
          message: 'Authentication failed',
          details: _extractErrorMessage(responseData) ?? 'Invalid credentials or expired session.',
          originalError: error,
        );

      case 403:
        return AuthenticationError(
          message: 'Access denied',
          details: _extractErrorMessage(responseData) ?? 'You do not have permission to perform this action.',
          originalError: error,
        );

      case 404:
        return ServerError(
          message: 'Not found',
          details: _extractErrorMessage(responseData) ?? 'The requested resource was not found.',
          statusCode: statusCode,
          originalError: error,
        );

      case 409:
        return ValidationError(
          message: 'Conflict',
          details: _extractErrorMessage(responseData) ?? 'This resource already exists.',
          originalError: error,
        );

      case 422:
        return ValidationError(
          message: 'Validation failed',
          details: _extractErrorMessage(responseData) ?? 'Please check your input and try again.',
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerError(
          message: 'Server error',
          details: 'The server is experiencing issues. Please try again later.',
          statusCode: statusCode,
          originalError: error,
        );

      default:
        return ServerError(
          message: 'Server error',
          details: _extractErrorMessage(responseData) ?? 'An error occurred on the server.',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  /// Extract error message from response data
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is Map) {
      // Try common error message fields
      if (responseData['message'] != null) {
        return responseData['message'].toString();
      }
      if (responseData['error'] != null) {
        return responseData['error'].toString();
      }
      if (responseData['detail'] != null) {
        return responseData['detail'].toString();
      }
    }

    if (responseData is String) {
      return responseData;
    }

    return null;
  }

  /// Get user-friendly message for display
  static String getUserMessage(AppError error) {
    return error.message;
  }

  /// Get detailed message for display (optional)
  static String? getDetailedMessage(AppError error) {
    return error.details;
  }

  /// Check if error is retryable
  static bool isRetryable(AppError error) {
    return error is NetworkError || 
           error is ServerError && (error.statusCode == null || error.statusCode! >= 500);
  }

  /// Check if error should trigger offline mode
  static bool shouldEnableOfflineMode(AppError error) {
    if (error is NetworkError) {
      final message = error.message.toLowerCase();
      return message.contains('no internet') || 
             message.contains('connection timeout') ||
             message.contains('unable to connect') ||
             message.contains('network unreachable') ||
             message.contains('connection failed');
    }
    return false;
  }
}
