import 'package:equatable/equatable.dart';
import '../../../data/models/trip.dart';
import '../../../data/models/observation.dart';

/// Base class for all trip states
abstract class TripState extends Equatable {
  const TripState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any trips are loaded
class TripInitial extends TripState {
  const TripInitial();
}

/// State when trips are being loaded
class TripsLoading extends TripState {
  const TripsLoading();
}

/// State when trips have been successfully loaded
class TripsLoaded extends TripState {
  final List<Trip> trips;

  const TripsLoaded(this.trips);

  @override
  List<Object?> get props => [trips];

  /// Create a copy with updated trips
  TripsLoaded copyWith({List<Trip>? trips}) {
    return TripsLoaded(trips ?? this.trips);
  }
}

/// State when a single trip is being loaded
class TripLoading extends TripState {
  const TripLoading();
}

/// State when a single trip has been loaded
class TripLoaded extends TripState {
  final Trip trip;

  const TripLoaded(this.trip);

  @override
  List<Object?> get props => [trip];
}

/// State when a trip is being created
class TripCreating extends TripState {
  const TripCreating();
}

/// State when a trip has been successfully created
class TripCreated extends TripState {
  final Trip trip;

  const TripCreated(this.trip);

  @override
  List<Object?> get props => [trip];
}

/// State when a trip is being updated
class TripUpdating extends TripState {
  const TripUpdating();
}

/// State when a trip has been successfully updated
class TripUpdated extends TripState {
  final Trip trip;

  const TripUpdated(this.trip);

  @override
  List<Object?> get props => [trip];
}

/// State when a trip is being deleted
class TripDeleting extends TripState {
  const TripDeleting();
}

/// State when a trip has been successfully deleted
class TripDeleted extends TripState {
  final String tripId;

  const TripDeleted(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// State when trip observations are being loaded
class TripObservationsLoading extends TripState {
  const TripObservationsLoading();
}

/// State when trip observations have been loaded
class TripObservationsLoaded extends TripState {
  final String tripId;
  final List<Observation> observations;

  const TripObservationsLoaded({
    required this.tripId,
    required this.observations,
  });

  @override
  List<Object?> get props => [tripId, observations];
}

/// State when an error occurs
class TripError extends TripState {
  final String message;

  const TripError(this.message);

  @override
  List<Object?> get props => [message];
}
