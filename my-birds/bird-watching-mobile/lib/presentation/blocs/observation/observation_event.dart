import 'package:equatable/equatable.dart';
import '../../../data/models/observation.dart';

/// Base class for observation events
abstract class ObservationEvent extends Equatable {
  const ObservationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all observations
class LoadObservations extends ObservationEvent {
  final bool forceRefresh;
  final String? userId;

  const LoadObservations({
    this.forceRefresh = false,
    this.userId,
  });

  @override
  List<Object?> get props => [forceRefresh, userId];

  @override
  String toString() => 'LoadObservations(forceRefresh: $forceRefresh, userId: $userId)';
}

/// Event to create a new observation
class CreateObservation extends ObservationEvent {
  final Observation observation;

  const CreateObservation(this.observation);

  @override
  List<Object?> get props => [observation];

  @override
  String toString() => 'CreateObservation(species: ${observation.speciesName})';
}

/// Event to update an existing observation
class UpdateObservation extends ObservationEvent {
  final Observation observation;

  const UpdateObservation(this.observation);

  @override
  List<Object?> get props => [observation];

  @override
  String toString() => 'UpdateObservation(id: ${observation.id})';
}

/// Event to delete an observation
class DeleteObservation extends ObservationEvent {
  final String id;

  const DeleteObservation(this.id);

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'DeleteObservation(id: $id)';
}

/// Event to sync pending observations
class SyncPendingObservations extends ObservationEvent {
  const SyncPendingObservations();
}

/// Event to search observations
class SearchObservations extends ObservationEvent {
  final String query;
  final String? userId;

  const SearchObservations({
    required this.query,
    this.userId,
  });

  @override
  List<Object?> get props => [query, userId];

  @override
  String toString() => 'SearchObservations(query: $query)';
}

/// Event to filter observations by date range
class FilterObservationsByDateRange extends ObservationEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? userId;

  const FilterObservationsByDateRange({
    required this.startDate,
    required this.endDate,
    this.userId,
  });

  @override
  List<Object?> get props => [startDate, endDate, userId];

  @override
  String toString() => 'FilterObservationsByDateRange(start: $startDate, end: $endDate)';
}

/// Event to clear filters and reload all observations
class ClearFilters extends ObservationEvent {
  final String? userId;

  const ClearFilters({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event to apply multiple filters
class ApplyFilters extends ObservationEvent {
  final String? species;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? userId;

  const ApplyFilters({
    this.species,
    this.location,
    this.startDate,
    this.endDate,
    this.userId,
  });

  @override
  List<Object?> get props => [species, location, startDate, endDate, userId];

  @override
  String toString() => 'ApplyFilters(species: $species, location: $location, '
      'startDate: $startDate, endDate: $endDate)';
}

/// Event to update connectivity status
class UpdateConnectivityStatus extends ObservationEvent {
  final bool isConnected;

  const UpdateConnectivityStatus(this.isConnected);

  @override
  List<Object?> get props => [isConnected];

  @override
  String toString() => 'UpdateConnectivityStatus(isConnected: $isConnected)';
}

/// Event to refresh pending sync count
class RefreshPendingSyncCount extends ObservationEvent {
  const RefreshPendingSyncCount();
}
