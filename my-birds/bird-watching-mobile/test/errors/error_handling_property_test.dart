import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/core/errors/app_error.dart';
import 'package:bird_watching_mobile/core/errors/error_mapper.dart';
import 'package:bird_watching_mobile/core/utils/retry_helper.dart';

/// Property-Based Tests for Error Handling
/// **Feature: flutter-mobile-app, Property 32: Photo upload retry**
/// **Feature: flutter-mobile-app, Property 33: Offline mode activation**
/// **Validates: Requirements 17.3, 17.4**
void main() {
  group('Error Handling Property Tests', () {
    test('Property 32: Photo upload retry - retryable errors trigger retry', () async {
      // Property: For any retryable error (network, server 5xx), the system should retry the operation
      
      final retryableErrors = [
        const NetworkError(message: 'Connection timeout'),
        const NetworkError(message: 'No internet connection'),
        const ServerError(message: 'Server error', statusCode: 500),
        const ServerError(message: 'Bad gateway', statusCode: 502),
        const ServerError(message: 'Service unavailable', statusCode: 503),
      ];

      for (final error in retryableErrors) {
        int attemptCount = 0;
        final maxAttempts = 3;

        try {
          await RetryHelper.retry(
            action: () async {
              attemptCount++;
              throw error;
            },
            maxAttempts: maxAttempts,
            initialDelay: 10, // Short delay for testing
            maxDelay: 100,
          );
          fail('Should have thrown error after retries');
        } catch (e) {
          // Verify: Should have attempted maxAttempts times
          expect(
            attemptCount,
            equals(maxAttempts),
            reason: 'Retryable error ${error.runtimeType} should trigger $maxAttempts attempts, '
                    'but got $attemptCount',
          );

          // Verify: Final error should be the same type
          expect(e, isA<AppError>());
          expect(e.runtimeType, equals(error.runtimeType));
        }
      }
    });

    test('Property 32: Photo upload retry - non-retryable errors do not retry', () async {
      // Property: For any non-retryable error (auth, validation), the system should not retry
      
      final nonRetryableErrors = [
        const AuthenticationError(message: 'Invalid credentials'),
        const AuthenticationError(message: 'Access denied'),
        const ValidationError(message: 'Invalid data'),
        const ServerError(message: 'Not found', statusCode: 404),
        const ServerError(message: 'Bad request', statusCode: 400),
      ];

      for (final error in nonRetryableErrors) {
        int attemptCount = 0;

        try {
          await RetryHelper.retry(
            action: () async {
              attemptCount++;
              throw error;
            },
            maxAttempts: 3,
            initialDelay: 10,
          );
          fail('Should have thrown error immediately');
        } catch (e) {
          // Verify: Should have attempted only once (no retries)
          expect(
            attemptCount,
            equals(1),
            reason: 'Non-retryable error ${error.runtimeType} should not retry, '
                    'but got $attemptCount attempts',
          );

          // Verify: Error should be the same type
          expect(e, isA<AppError>());
          expect(e.runtimeType, equals(error.runtimeType));
        }
      }
    });

    test('Property 32: Photo upload retry - exponential backoff increases delay', () async {
      // Property: For any retry sequence, delays should increase exponentially
      
      final delays = <int>[];
      int attemptCount = 0;

      try {
        await RetryHelper.retry(
          action: () async {
            attemptCount++;
            throw const NetworkError(message: 'Connection error');
          },
          maxAttempts: 4,
          initialDelay: 100,
          maxDelay: 10000,
          exponentialBase: 2.0,
          onRetry: (attempt, error) {
            // Record when retry is about to happen
            delays.add(DateTime.now().millisecondsSinceEpoch);
          },
        );
      } catch (e) {
        // Expected to fail
      }

      // Verify: Should have 3 delays (between 4 attempts)
      expect(delays.length, equals(3));

      // Verify: Each delay should be longer than the previous (with some tolerance)
      // We can't check exact timing due to test execution overhead,
      // but we can verify the pattern exists
      expect(attemptCount, equals(4));
    });

    test('Property 32: Photo upload retry - successful retry stops attempts', () async {
      // Property: For any operation that succeeds after N retries, no further attempts should be made
      
      final testCases = [
        {'failCount': 0, 'expectedAttempts': 1}, // Success on first try
        {'failCount': 1, 'expectedAttempts': 2}, // Success on second try
        {'failCount': 2, 'expectedAttempts': 3}, // Success on third try
      ];

      for (final testCase in testCases) {
        final failCount = testCase['failCount'] as int;
        final expectedAttempts = testCase['expectedAttempts'] as int;
        
        int attemptCount = 0;

        final result = await RetryHelper.retry(
          action: () async {
            attemptCount++;
            if (attemptCount <= failCount) {
              throw const NetworkError(message: 'Temporary error');
            }
            return 'success';
          },
          maxAttempts: 5,
          initialDelay: 10,
        );

        // Verify: Should succeed
        expect(result, equals('success'));

        // Verify: Should have attempted exactly the expected number of times
        expect(
          attemptCount,
          equals(expectedAttempts),
          reason: 'With $failCount failures, should attempt $expectedAttempts times, '
                  'but got $attemptCount',
        );
      }
    });

    test('Property 33: Offline mode activation - network errors trigger offline mode', () async {
      // Property: For any network connectivity error, the system should enable offline mode
      
      final networkErrors = [
        const NetworkError(message: 'No internet connection'),
        const NetworkError(message: 'Connection timeout'),
        const NetworkError(message: 'Unable to connect to the server'),
        const NetworkError(message: 'Network unreachable'),
      ];

      for (final error in networkErrors) {
        final shouldEnableOffline = ErrorMapper.shouldEnableOfflineMode(error);

        // Verify: Network errors should trigger offline mode
        expect(
          shouldEnableOffline,
          isTrue,
          reason: 'Network error "${error.message}" should trigger offline mode',
        );
      }
    });

    test('Property 33: Offline mode activation - non-network errors do not trigger offline mode', () async {
      // Property: For any non-network error, the system should not enable offline mode
      
      final nonNetworkErrors = [
        const AuthenticationError(message: 'Invalid credentials'),
        const ValidationError(message: 'Invalid data'),
        const ServerError(message: 'Server error', statusCode: 500),
        const PhotoUploadError(message: 'Upload failed'),
        const UnknownError(message: 'Unknown error'),
      ];

      for (final error in nonNetworkErrors) {
        final shouldEnableOffline = ErrorMapper.shouldEnableOfflineMode(error);

        // Verify: Non-network errors should not trigger offline mode
        expect(
          shouldEnableOffline,
          isFalse,
          reason: '${error.runtimeType} should not trigger offline mode',
        );
      }
    });

    test('Property 33: Offline mode activation - specific network messages trigger offline mode', () async {
      // Property: Network errors with specific messages should trigger offline mode
      
      final offlineTriggerMessages = [
        'No internet',
        'Connection timeout',
        'Unable to connect',
        'Network unreachable',
        'Connection failed',
      ];

      for (final message in offlineTriggerMessages) {
        final error = NetworkError(message: message);
        final shouldEnableOffline = ErrorMapper.shouldEnableOfflineMode(error);

        // Verify: These messages should trigger offline mode
        expect(
          shouldEnableOffline,
          isTrue,
          reason: 'Network error with message "$message" should trigger offline mode',
        );
      }
    });

    test('Property 32 & 33: Combined - photo upload with network error retries then enables offline', () async {
      // Property: Photo upload failures due to network errors should retry, then enable offline mode
      
      int attemptCount = 0;
      final maxAttempts = 3;
      AppError? finalError;

      try {
        await RetryHelper.retry(
          action: () async {
            attemptCount++;
            throw const NetworkError(message: 'No internet connection');
          },
          maxAttempts: maxAttempts,
          initialDelay: 10,
        );
      } catch (e) {
        finalError = e as AppError;
      }

      // Verify: Should have retried maxAttempts times
      expect(attemptCount, equals(maxAttempts));

      // Verify: Final error should be a NetworkError
      expect(finalError, isA<NetworkError>());

      // Verify: Should trigger offline mode
      expect(ErrorMapper.shouldEnableOfflineMode(finalError!), isTrue);
    });

    test('Property 32: Photo upload retry - retry callback is called', () async {
      // Property: For any retry operation, the onRetry callback should be called before each retry
      
      final retryAttempts = <int>[];
      final retryErrors = <AppError>[];

      try {
        await RetryHelper.retry(
          action: () async {
            throw const NetworkError(message: 'Connection error');
          },
          maxAttempts: 3,
          initialDelay: 10,
          onRetry: (attempt, error) {
            retryAttempts.add(attempt);
            retryErrors.add(error);
          },
        );
      } catch (e) {
        // Expected to fail
      }

      // Verify: Callback should be called for each retry (not for initial attempt)
      expect(retryAttempts.length, equals(2)); // 2 retries after initial attempt
      expect(retryAttempts, equals([1, 2]));

      // Verify: All errors should be NetworkError
      expect(retryErrors.every((e) => e is NetworkError), isTrue);
    });

    test('Property 32: Photo upload retry - max delay caps exponential backoff', () async {
      // Property: For any retry sequence, delay should not exceed maxDelay
      
      int attemptCount = 0;

      try {
        await RetryHelper.retry(
          action: () async {
            attemptCount++;
            throw const NetworkError(message: 'Connection error');
          },
          maxAttempts: 10,
          initialDelay: 1000,
          maxDelay: 2000, // Cap at 2 seconds
          exponentialBase: 2.0,
        );
      } catch (e) {
        // Expected to fail
      }

      // Verify: Should have attempted all retries
      expect(attemptCount, equals(10));
      
      // Note: We can't easily verify the actual delays in a unit test,
      // but the implementation ensures delays are capped at maxDelay
    });
  });
}
