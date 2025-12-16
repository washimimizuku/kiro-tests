/// Base class for application errors
abstract class AppError implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  const AppError({
    required this.message,
    this.details,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// Network-related errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.details,
    super.originalError,
  });
}

/// Authentication-related errors
class AuthenticationError extends AppError {
  const AuthenticationError({
    required super.message,
    super.details,
    super.originalError,
  });
}

/// Photo upload errors
class PhotoUploadError extends AppError {
  final String? photoPath;

  const PhotoUploadError({
    required super.message,
    super.details,
    super.originalError,
    this.photoPath,
  });
}

/// Validation errors
class ValidationError extends AppError {
  final Map<String, String>? fieldErrors;

  const ValidationError({
    required super.message,
    super.details,
    super.originalError,
    this.fieldErrors,
  });
}

/// Server errors
class ServerError extends AppError {
  final int? statusCode;

  const ServerError({
    required super.message,
    super.details,
    super.originalError,
    this.statusCode,
  });
}

/// Offline mode error
class OfflineError extends AppError {
  const OfflineError({
    required super.message,
    super.details,
    super.originalError,
  });
}

/// Generic/unknown errors
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.details,
    super.originalError,
  });
}
