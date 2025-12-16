import 'package:equatable/equatable.dart';
import '../../../data/models/sync_result.dart';

/// Base class for all sync states
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any sync operations
class SyncIdle extends SyncState {
  final bool autoSyncEnabled;

  const SyncIdle({this.autoSyncEnabled = true});

  @override
  List<Object?> get props => [autoSyncEnabled];
}

/// State when sync is in progress
class Syncing extends SyncState {
  final int current;
  final int total;
  final String? currentObservationId;

  const Syncing({
    required this.current,
    required this.total,
    this.currentObservationId,
  });

  /// Calculate progress as a percentage (0.0 to 1.0)
  double get progress => total > 0 ? current / total : 0.0;

  @override
  List<Object?> get props => [current, total, currentObservationId];

  /// Create a copy with updated values
  Syncing copyWith({
    int? current,
    int? total,
    String? currentObservationId,
  }) {
    return Syncing(
      current: current ?? this.current,
      total: total ?? this.total,
      currentObservationId: currentObservationId ?? this.currentObservationId,
    );
  }
}

/// State when sync has completed successfully
class SyncComplete extends SyncState {
  final int synced;
  final SyncResult result;

  const SyncComplete({
    required this.synced,
    required this.result,
  });

  @override
  List<Object?> get props => [synced, result];
}

/// State when sync encounters an error
class SyncError extends SyncState {
  final String message;
  final int failed;
  final SyncResult? result;

  const SyncError({
    required this.message,
    this.failed = 0,
    this.result,
  });

  @override
  List<Object?> get props => [message, failed, result];
}
