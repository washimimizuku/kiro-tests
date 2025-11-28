import 'package:equatable/equatable.dart';
import '../../../data/models/observation.dart';

/// Base class for observation states
abstract class ObservationState extends Equatable {
  const ObservationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ObservationInitial extends ObservationState {
  const ObservationInitial();
}

/// State when observations are being loaded
class ObservationsLoading extends ObservationState {
  const ObservationsLoading();
}

/// State when observations are loaded successfully
class ObservationsLoaded extends ObservationState {
  final List<Observation> observations;
  final int pendingSyncCount;
  final bool isOffline;

  const ObservationsLoaded({
    required this.observations,
    this.pendingSyncCount = 0,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [observations, pendingSyncCount, isOffline];

  ObservationsLoaded copyWith({
    List<Observation>? observations,
    int? pendingSyncCount,
    bool? isOffline,
  }) {
    return ObservationsLoaded(
      observations: observations ?? this.observations,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  String toString() => 'ObservationsLoaded(count: ${observations.length}, '
      'pendingSync: $pendingSyncCount, offline: $isOffline)';
}

/// State when observation operation fails
class ObservationError extends ObservationState {
  final String message;

  const ObservationError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ObservationError(message: $message)';
}

/// State when a single observation is being created
class ObservationCreating extends ObservationState {
  const ObservationCreating();
}

/// State when a single observation is created successfully
class ObservationCreated extends ObservationState {
  final Observation observation;

  const ObservationCreated(this.observation);

  @override
  List<Object?> get props => [observation];
}

/// State when a single observation is being updated
class ObservationUpdating extends ObservationState {
  const ObservationUpdating();
}

/// State when a single observation is updated successfully
class ObservationUpdated extends ObservationState {
  final Observation observation;

  const ObservationUpdated(this.observation);

  @override
  List<Object?> get props => [observation];
}

/// State when a single observation is being deleted
class ObservationDeleting extends ObservationState {
  const ObservationDeleting();
}

/// State when a single observation is deleted successfully
class ObservationDeleted extends ObservationState {
  final String observationId;

  const ObservationDeleted(this.observationId);

  @override
  List<Object?> get props => [observationId];
}
