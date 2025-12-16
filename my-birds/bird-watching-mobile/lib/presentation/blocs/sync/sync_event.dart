import 'package:equatable/equatable.dart';
import '../../../data/models/observation.dart';

/// Base class for all sync events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start syncing all pending observations
class StartSync extends SyncEvent {
  const StartSync();
}

/// Event to sync a single observation
class SyncSingleObservation extends SyncEvent {
  final Observation observation;

  const SyncSingleObservation(this.observation);

  @override
  List<Object?> get props => [observation];
}

/// Event to update sync progress
class UpdateSyncProgress extends SyncEvent {
  final int current;
  final int total;
  final String? currentObservationId;

  const UpdateSyncProgress({
    required this.current,
    required this.total,
    this.currentObservationId,
  });

  @override
  List<Object?> get props => [current, total, currentObservationId];
}

/// Event to enable or disable auto-sync
class SetAutoSync extends SyncEvent {
  final bool enabled;

  const SetAutoSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to cancel ongoing sync
class CancelSync extends SyncEvent {
  const CancelSync();
}
