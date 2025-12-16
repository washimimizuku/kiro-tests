import 'package:equatable/equatable.dart';
import '../../../data/models/observation.dart';

/// Represents a map marker with observation data
class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final Observation observation;

  const MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.observation,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapMarker &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.observation == observation;
  }

  @override
  int get hashCode {
    return Object.hash(id, latitude, longitude, observation);
  }
}

/// Represents map center position
class MapPosition {
  final double latitude;
  final double longitude;
  final double zoom;

  const MapPosition({
    required this.latitude,
    required this.longitude,
    this.zoom = 10.0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapPosition &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.zoom == zoom;
  }

  @override
  int get hashCode {
    return Object.hash(latitude, longitude, zoom);
  }
}

/// Base class for all map states
abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

/// Initial state before map is loaded
class MapInitial extends MapState {
  const MapInitial();
}

/// State when map data is being loaded
class MapLoading extends MapState {
  const MapLoading();
}

/// State when map is loaded with markers
class MapLoaded extends MapState {
  final List<MapMarker> markers;
  final MapPosition? center;
  final Observation? selectedObservation;
  final bool clusteringEnabled;
  final String? speciesFilter;
  final String? locationFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const MapLoaded({
    required this.markers,
    this.center,
    this.selectedObservation,
    this.clusteringEnabled = true,
    this.speciesFilter,
    this.locationFilter,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [
        markers,
        center,
        selectedObservation,
        clusteringEnabled,
        speciesFilter,
        locationFilter,
        startDate,
        endDate,
      ];

  /// Check if any filters are active
  bool get hasActiveFilters =>
      speciesFilter != null ||
      locationFilter != null ||
      startDate != null ||
      endDate != null;

  /// Create a copy with updated values
  MapLoaded copyWith({
    List<MapMarker>? markers,
    MapPosition? center,
    Observation? selectedObservation,
    bool? clearSelection,
    bool? clusteringEnabled,
    String? speciesFilter,
    bool? clearSpeciesFilter,
    String? locationFilter,
    bool? clearLocationFilter,
    DateTime? startDate,
    bool? clearStartDate,
    DateTime? endDate,
    bool? clearEndDate,
  }) {
    return MapLoaded(
      markers: markers ?? this.markers,
      center: center ?? this.center,
      selectedObservation: clearSelection == true
          ? null
          : (selectedObservation ?? this.selectedObservation),
      clusteringEnabled: clusteringEnabled ?? this.clusteringEnabled,
      speciesFilter: clearSpeciesFilter == true
          ? null
          : (speciesFilter ?? this.speciesFilter),
      locationFilter: clearLocationFilter == true
          ? null
          : (locationFilter ?? this.locationFilter),
      startDate: clearStartDate == true ? null : (startDate ?? this.startDate),
      endDate: clearEndDate == true ? null : (endDate ?? this.endDate),
    );
  }
}

/// State when an error occurs
class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}
