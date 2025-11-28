import 'dart:async';

/// Utility class for debouncing function calls
/// Delays execution until a specified duration has passed without new calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Call the provided function after the delay
  /// Cancels any pending calls
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel any pending calls
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of the debouncer
  void dispose() {
    _timer?.cancel();
  }
}
