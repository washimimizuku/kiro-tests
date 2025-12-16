import 'package:equatable/equatable.dart';
import '../../../data/models/trip.dart';

/// Base class for all trip events
abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all trips
class LoadTrips extends TripEvent {
  final bool forceRefresh;
  final String? userId;

  const LoadTrips({
    this.forceRefresh = false,
    this.userId,
  });

  @override
  List<Object?> get props => [forceRefresh, userId];
}

/// Event to load a specific trip by ID
class LoadTripById extends TripEvent {
  final String tripId;

  const LoadTripById(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to create a new trip
class CreateTrip extends TripEvent {
  final Trip trip;

  const CreateTrip(this.trip);

  @override
  List<Object?> get props => [trip];
}

/// Event to update an existing trip
class UpdateTrip extends TripEvent {
  final Trip trip;

  const UpdateTrip(this.trip);

  @override
  List<Object?> get props => [trip];
}

/// Event to delete a trip
class DeleteTrip extends TripEvent {
  final String tripId;

  const DeleteTrip(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to load observations for a specific trip
class LoadTripObservations extends TripEvent {
  final String tripId;

  const LoadTripObservations(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Event to add an observation to a trip
class AddObservationToTrip extends TripEvent {
  final String tripId;
  final String observationId;

  const AddObservationToTrip({
    required this.tripId,
    required this.observationId,
  });

  @override
  List<Object?> get props => [tripId, observationId];
}

/// Event to remove an observation from a trip
class RemoveObservationFromTrip extends TripEvent {
  final String tripId;
  final String observationId;

  const RemoveObservationFromTrip({
    required this.tripId,
    required this.observationId,
  });

  @override
  List<Object?> get props => [tripId, observationId];
}
