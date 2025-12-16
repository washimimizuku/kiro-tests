import 'package:equatable/equatable.dart';
import '../../../data/models/observation.dart';

/// Base class for all map events
abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load observations for map display
class LoadMapObservations extends MapEvent {
  final String? userId;
  final bool sharedOnly;

  const LoadMapObservations({
    this.userId,
    this.sharedOnly = false,
  });

  @override
  List<Object?> get props => [userId, sharedOnly];
}

/// Event to update map markers
class UpdateMapMarkers extends MapEvent {
  final List<Observation> observations;

  const UpdateMapMarkers(this.observations);

  @override
  List<Object?> get props => [observations];
}

/// Event to select an observation marker
class SelectObservation extends MapEvent {
  final Observation observation;

  const SelectObservation(this.observation);

  @override
  List<Object?> get props => [observation];
}

/// Event to deselect the current observation
class DeselectObservation extends MapEvent {
  const DeselectObservation();
}

/// Event to update map center position
class UpdateMapCenter extends MapEvent {
  final double latitude;
  final double longitude;
  final double? zoom;

  const UpdateMapCenter({
    required this.latitude,
    required this.longitude,
    this.zoom,
  });

  @override
  List<Object?> get props => [latitude, longitude, zoom];
}

/// Event to center map on user's current location
class CenterOnCurrentLocation extends MapEvent {
  const CenterOnCurrentLocation();
}

/// Event to enable or disable marker clustering
class SetClusteringEnabled extends MapEvent {
  final bool enabled;

  const SetClusteringEnabled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to filter observations on map
class FilterMapObservations extends MapEvent {
  final String? speciesFilter;
  final String? locationFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterMapObservations({
    this.speciesFilter,
    this.locationFilter,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [speciesFilter, locationFilter, startDate, endDate];
}

/// Event to clear all map filters
class ClearMapFilters extends MapEvent {
  const ClearMapFilters();
}
