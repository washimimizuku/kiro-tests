import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/core/utils/debouncer.dart';

/// Property-Based Test for Search Debouncing
/// **Feature: flutter-mobile-app, Property 24: Search debouncing**
/// **Validates: Requirements 11.5**
///
/// Property: For any rapid sequence of search inputs within a short time window (300ms),
/// only the final input should trigger an API call.
void main() {
  group('Debouncer Property Tests', () {
    test('Property 24: Search debouncing - rapid inputs only trigger final call', () async {
      // Property: For any rapid sequence of inputs within 300ms, only the final input executes
      
      // Test with various input sequences
      final testCases = [
        {'inputs': 3, 'delay': 50}, // 3 inputs, 50ms apart
        {'inputs': 5, 'delay': 30}, // 5 inputs, 30ms apart
        {'inputs': 10, 'delay': 20}, // 10 inputs, 20ms apart
        {'inputs': 2, 'delay': 100}, // 2 inputs, 100ms apart
        {'inputs': 7, 'delay': 40}, // 7 inputs, 40ms apart
      ];

      for (final testCase in testCases) {
        final inputCount = testCase['inputs'] as int;
        final delayMs = testCase['delay'] as int;
        
        int callCount = 0;
        String? lastValue;
        
        final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
        
        // Simulate rapid inputs
        for (int i = 0; i < inputCount; i++) {
          final value = 'input_$i';
          debouncer.call(() {
            callCount++;
            lastValue = value;
          });
          
          // Wait between inputs (less than debounce delay)
          await Future.delayed(Duration(milliseconds: delayMs));
        }
        
        // Wait for debounce to complete
        await Future.delayed(const Duration(milliseconds: 400));
        
        // Verify: Only one call should have been made (the last one)
        expect(
          callCount,
          equals(1),
          reason: 'For $inputCount rapid inputs with ${delayMs}ms delay, '
                  'only 1 call should execute, but got $callCount',
        );
        
        // Verify: The last input value should be the one that executed
        expect(
          lastValue,
          equals('input_${inputCount - 1}'),
          reason: 'The final input should be the one that executes',
        );
        
        debouncer.dispose();
      }
    });

    test('Property 24: Search debouncing - inputs after delay trigger new call', () async {
      // Property: Inputs separated by more than the debounce delay should each trigger a call
      
      int callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      
      // First input
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 400));
      
      expect(callCount, equals(1), reason: 'First input should trigger call');
      
      // Second input after delay
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 400));
      
      expect(callCount, equals(2), reason: 'Second input after delay should trigger new call');
      
      // Third input after delay
      debouncer.call(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 400));
      
      expect(callCount, equals(3), reason: 'Third input after delay should trigger new call');
      
      debouncer.dispose();
    });

    test('Property 24: Search debouncing - cancel prevents execution', () async {
      // Property: Canceling a debounced call should prevent execution
      
      int callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      
      // Schedule a call
      debouncer.call(() => callCount++);
      
      // Cancel before it executes
      await Future.delayed(const Duration(milliseconds: 100));
      debouncer.cancel();
      
      // Wait past the debounce delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verify: No call should have been made
      expect(callCount, equals(0), reason: 'Canceled call should not execute');
      
      debouncer.dispose();
    });

    test('Property 24: Search debouncing - empty input clears search', () async {
      // Property: Empty input after debounce should trigger a clear/reload action
      
      int callCount = 0;
      String? lastQuery;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 300));
      
      // Type some text
      debouncer.call(() {
        callCount++;
        lastQuery = 'bird';
      });
      
      await Future.delayed(const Duration(milliseconds: 400));
      expect(callCount, equals(1));
      expect(lastQuery, equals('bird'));
      
      // Clear the search (empty string)
      debouncer.call(() {
        callCount++;
        lastQuery = '';
      });
      
      await Future.delayed(const Duration(milliseconds: 400));
      expect(callCount, equals(2));
      expect(lastQuery, equals(''), reason: 'Empty query should trigger clear action');
      
      debouncer.dispose();
    });

    test('Property 24: Search debouncing - multiple debouncers are independent', () async {
      // Property: Multiple debouncer instances should not interfere with each other
      
      int callCount1 = 0;
      int callCount2 = 0;
      
      final debouncer1 = Debouncer(delay: const Duration(milliseconds: 300));
      final debouncer2 = Debouncer(delay: const Duration(milliseconds: 300));
      
      // Trigger both debouncers
      debouncer1.call(() => callCount1++);
      debouncer2.call(() => callCount2++);
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Both should execute independently
      expect(callCount1, equals(1), reason: 'First debouncer should execute');
      expect(callCount2, equals(1), reason: 'Second debouncer should execute');
      
      debouncer1.dispose();
      debouncer2.dispose();
    });

    test('Property 24: Search debouncing - timing precision', () async {
      // Property: Debouncer should respect the specified delay duration
      
      final delays = [100, 200, 300, 500];
      
      for (final delayMs in delays) {
        int callCount = 0;
        final debouncer = Debouncer(delay: Duration(milliseconds: delayMs));
        final startTime = DateTime.now();
        
        debouncer.call(() {
          callCount++;
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          
          // Verify timing (allow 50ms tolerance for test execution overhead)
          expect(
            elapsed,
            greaterThanOrEqualTo(delayMs - 50),
            reason: 'Call should not execute before delay of ${delayMs}ms',
          );
          expect(
            elapsed,
            lessThanOrEqualTo(delayMs + 100),
            reason: 'Call should execute within reasonable time after delay of ${delayMs}ms',
          );
        });
        
        // Wait for execution
        await Future.delayed(Duration(milliseconds: delayMs + 100));
        
        expect(callCount, equals(1), reason: 'Call should execute after ${delayMs}ms delay');
        
        debouncer.dispose();
      }
    });
  });
}
