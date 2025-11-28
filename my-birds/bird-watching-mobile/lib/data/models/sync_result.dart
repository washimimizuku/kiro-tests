/// SyncResult model representing the result of a sync operation
class SyncResult {
  final int totalAttempted;
  final int successful;
  final int failed;
  final List<String> failedIds;
  final List<String> errors;

  const SyncResult({
    required this.totalAttempted,
    required this.successful,
    required this.failed,
    required this.failedIds,
    required this.errors,
  });

  /// Creates an empty SyncResult (no operations attempted)
  factory SyncResult.empty() {
    return const SyncResult(
      totalAttempted: 0,
      successful: 0,
      failed: 0,
      failedIds: [],
      errors: [],
    );
  }

  /// Creates a successful SyncResult
  factory SyncResult.success(int count) {
    return SyncResult(
      totalAttempted: count,
      successful: count,
      failed: 0,
      failedIds: const [],
      errors: const [],
    );
  }

  /// Creates a failed SyncResult
  factory SyncResult.failure(int count, List<String> failedIds, List<String> errors) {
    return SyncResult(
      totalAttempted: count,
      successful: 0,
      failed: count,
      failedIds: failedIds,
      errors: errors,
    );
  }

  /// Creates a partial SyncResult (some succeeded, some failed)
  factory SyncResult.partial({
    required int totalAttempted,
    required int successful,
    required int failed,
    required List<String> failedIds,
    required List<String> errors,
  }) {
    return SyncResult(
      totalAttempted: totalAttempted,
      successful: successful,
      failed: failed,
      failedIds: failedIds,
      errors: errors,
    );
  }

  /// Returns true if all sync operations were successful
  bool get isFullSuccess => totalAttempted > 0 && failed == 0;

  /// Returns true if all sync operations failed
  bool get isFullFailure => totalAttempted > 0 && successful == 0;

  /// Returns true if some operations succeeded and some failed
  bool get isPartialSuccess => successful > 0 && failed > 0;

  /// Returns true if no operations were attempted
  bool get isEmpty => totalAttempted == 0;

  /// Returns the success rate as a percentage (0.0 to 1.0)
  double get successRate {
    if (totalAttempted == 0) return 0.0;
    return successful / totalAttempted;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncResult &&
        other.totalAttempted == totalAttempted &&
        other.successful == successful &&
        other.failed == failed &&
        _listEquals(other.failedIds, failedIds) &&
        _listEquals(other.errors, errors);
  }

  @override
  int get hashCode {
    return Object.hash(
      totalAttempted,
      successful,
      failed,
      Object.hashAll(failedIds),
      Object.hashAll(errors),
    );
  }

  @override
  String toString() {
    return 'SyncResult(totalAttempted: $totalAttempted, successful: $successful, '
        'failed: $failed, failedIds: $failedIds, errors: $errors)';
  }

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
