import 'dart:async';
import '../errors/app_error.dart';
import '../errors/error_mapper.dart';

/// Helper class for implementing retry logic with exponential backoff
class RetryHelper {
  /// Execute a function with retry logic
  /// 
  /// [action] - The function to execute
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry in milliseconds (default: 1000ms)
  /// [maxDelay] - Maximum delay between retries in milliseconds (default: 10000ms)
  /// [exponentialBase] - Base for exponential backoff (default: 2)
  /// [onRetry] - Optional callback called before each retry with attempt number
  static Future<T> retry<T>({
    required Future<T> Function() action,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    double exponentialBase = 2.0,
    void Function(int attempt, AppError error)? onRetry,
  }) async {
    int attempt = 0;
    AppError? lastError;

    while (attempt < maxAttempts) {
      try {
        return await action();
      } catch (error) {
        attempt++;
        lastError = ErrorMapper.mapError(error);

        // Don't retry if error is not retryable
        if (!ErrorMapper.isRetryable(lastError)) {
          throw lastError;
        }

        // Don't retry if we've exhausted attempts
        if (attempt >= maxAttempts) {
          throw lastError;
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(
          attempt: attempt,
          initialDelay: initialDelay,
          maxDelay: maxDelay,
          exponentialBase: exponentialBase,
        );

        // Call retry callback if provided
        onRetry?.call(attempt, lastError);

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? const UnknownError(message: 'Retry failed');
  }

  /// Calculate delay for exponential backoff
  static int _calculateDelay({
    required int attempt,
    required int initialDelay,
    required int maxDelay,
    required double exponentialBase,
  }) {
    // Calculate exponential delay: initialDelay * (base ^ (attempt - 1))
    final delay = (initialDelay * (exponentialBase * (attempt - 1))).round();
    
    // Cap at maxDelay
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Execute with simple retry (no exponential backoff)
  static Future<T> retrySimple<T>({
    required Future<T> Function() action,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    void Function(int attempt, AppError error)? onRetry,
  }) async {
    int attempt = 0;
    AppError? lastError;

    while (attempt < maxAttempts) {
      try {
        return await action();
      } catch (error) {
        attempt++;
        lastError = ErrorMapper.mapError(error);

        // Don't retry if error is not retryable
        if (!ErrorMapper.isRetryable(lastError)) {
          throw lastError;
        }

        // Don't retry if we've exhausted attempts
        if (attempt >= maxAttempts) {
          throw lastError;
        }

        // Call retry callback if provided
        onRetry?.call(attempt, lastError);

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? const UnknownError(message: 'Retry failed');
  }
}

/// Mixin for adding retry functionality to classes
mixin RetryMixin {
  Future<T> retryOperation<T>({
    required Future<T> Function() action,
    int maxAttempts = 3,
    int initialDelay = 1000,
    int maxDelay = 10000,
    void Function(int attempt, AppError error)? onRetry,
  }) {
    return RetryHelper.retry(
      action: action,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
      onRetry: onRetry,
    );
  }
}
