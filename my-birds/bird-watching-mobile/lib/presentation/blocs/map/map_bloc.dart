import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/observation_repository.dart';
import '../../../data/services/gps_service.dart';
import 'map_event.dart';
import 'map_state.dart';

/// BLoC for managing map state
/// Handles marker management and clustering logic
class MapBloc extends Bloc<MapEvent, MapState> {
  final ObservationRepository _observationRepository;
  final GpsService _gpsService;

  MapBloc({
    required ObservationRepository observationRepository,
    required GpsService gpsService,
  })  : _observationRepository = observationRepository,
        _gpsService = gpsService,
        super(const MapInitial()) {
    on<LoadMapObservations>(_onLoadMapObservations);
    on<UpdateMapMarkers>(_onUpdateMapMarkers);
    on<SelectObservation>(_onSelectObservation);
    on<DeselectObservation>(_onDeselectObservation);
    on<UpdateMapCenter>(_onUpdateMapCenter);
    on<CenterOnCurrentLocation>(_onCenterOnCurrentLocation);
    on<SetClusteringEnabled>(_onSetClusteringEnabled);
    on<FilterMapObservations>(_onFilterMapObservations);
    on<ClearMapFilters>(_onClearMapFilters);
  }

  /// Handle loading observations for map display
  Future<void> _onLoadMapObservations(
    LoadMapObservations event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());

    try {
      print('[MapBloc] Loading observations for map (sharedOnly: ${event.sharedOnly})');

      // Get observations
      List<dynamic> observations;
      if (event.sharedOnly) {
        observations = await _observationRepository.getSharedObservations();
      } else {
        observations = await _observationRepository.getObservations(
          userId: event.userId,
        );
      }

      // Filter observations with coordinates
      final observationsWithCoords = observations
          .where((obs) => obs.latitude != null && obs.longitude != null)
          .toList();

      print('[MapBloc] Found ${observationsWithCoords.length} observations with coordinates');

      // Create markers
      final markers = observationsWithCoords
          .map((obs) => MapMarker(
                id: obs.id,
                latitude: obs.latitude!,
                longitude: obs.longitude!,
                observation: obs,
              ))
          .toList();

      // Calculate center position
      MapPosition? center;
      if (markers.isNotEmpty) {
        center = _calculateCenter(markers);
      }

      emit(MapLoaded(
        markers: markers,
        center: center,
        clusteringEnabled: true,
      ));
    } catch (e) {
      print('[MapBloc] Error loading map observations: $e');
      emit(MapError(e.toString()));
    }
  }

  /// Handle updating map markers
  Future<void> _onUpdateMapMarkers(
    UpdateMapMarkers event,
    Emitter<MapState> emit,
  ) async {
    try {
      print('[MapBloc] Updating map markers');

      // Filter observations with coordinates
      final observationsWithCoords = event.observations
          .where((obs) => obs.latitude != null && obs.longitude != null)
          .toList();

      // Create markers
      final markers = observationsWithCoords
          .map((obs) => MapMarker(
                id: obs.id,
                latitude: obs.latitude!,
                longitude: obs.longitude!,
                observation: obs,
              ))
          .toList();

      // Calculate center position
      MapPosition? center;
      if (markers.isNotEmpty) {
        center = _calculateCenter(markers);
      }

      if (state is MapLoaded) {
        final currentState = state as MapLoaded;
        emit(currentState.copyWith(
          markers: markers,
          center: center,
        ));
      } else {
        emit(MapLoaded(
          markers: markers,
          center: center,
          clusteringEnabled: true,
        ));
      }
    } catch (e) {
      print('[MapBloc] Error updating map markers: $e');
      emit(MapError(e.toString()));
    }
  }

  /// Handle selecting an observation marker
  Future<void> _onSelectObservation(
    SelectObservation event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      print('[MapBloc] Selecting observation: ${event.observation.id}');
      
      emit(currentState.copyWith(
        selectedObservation: event.observation,
      ));
    }
  }

  /// Handle deselecting the current observation
  Future<void> _onDeselectObservation(
    DeselectObservation event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      print('[MapBloc] Deselecting observation');
      
      emit(currentState.copyWith(clearSelection: true));
    }
  }

  /// Handle updating map center position
  Future<void> _onUpdateMapCenter(
    UpdateMapCenter event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      print('[MapBloc] Updating map center: (${event.latitude}, ${event.longitude})');
      
      emit(currentState.copyWith(
        center: MapPosition(
          latitude: event.latitude,
          longitude: event.longitude,
          zoom: event.zoom ?? currentState.center?.zoom ?? 10.0,
        ),
      ));
    }
  }

  /// Handle centering map on user's current location
  Future<void> _onCenterOnCurrentLocation(
    CenterOnCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    try {
      print('[MapBloc] Centering on current location');

      final position = await _gpsService.getCurrentPosition();

      if (position == null) {
        print('[MapBloc] Could not get current location');
        return;
      }

      if (state is MapLoaded) {
        final currentState = state as MapLoaded;
        emit(currentState.copyWith(
          center: MapPosition(
            latitude: position.latitude,
            longitude: position.longitude,
            zoom: 15.0, // Zoom in when centering on user
          ),
        ));
      }
    } catch (e) {
      print('[MapBloc] Error centering on current location: $e');
      // Don't emit error state, just log it
    }
  }

  /// Handle enabling/disabling marker clustering
  Future<void> _onSetClusteringEnabled(
    SetClusteringEnabled event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      print('[MapBloc] Setting clustering enabled: ${event.enabled}');
      
      emit(currentState.copyWith(clusteringEnabled: event.enabled));
    }
  }

  /// Handle filtering observations on map
  Future<void> _onFilterMapObservations(
    FilterMapObservations event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());

    try {
      print('[MapBloc] Filtering map observations');

      // Get all observations
      final observations = await _observationRepository.getObservations();

      // Apply filters
      var filteredObservations = observations.where((obs) {
        // Filter by species
        if (event.speciesFilter != null && event.speciesFilter!.isNotEmpty) {
          if (!obs.speciesName
              .toLowerCase()
              .contains(event.speciesFilter!.toLowerCase())) {
            return false;
          }
        }

        // Filter by location
        if (event.locationFilter != null && event.locationFilter!.isNotEmpty) {
          if (!obs.location
              .toLowerCase()
              .contains(event.locationFilter!.toLowerCase())) {
            return false;
          }
        }

        // Filter by date range
        if (event.startDate != null) {
          if (obs.observationDate.isBefore(event.startDate!)) {
            return false;
          }
        }

        if (event.endDate != null) {
          if (obs.observationDate.isAfter(event.endDate!)) {
            return false;
          }
        }

        // Must have coordinates
        return obs.latitude != null && obs.longitude != null;
      }).toList();

      print('[MapBloc] Filtered to ${filteredObservations.length} observations');

      // Create markers
      final markers = filteredObservations
          .map((obs) => MapMarker(
                id: obs.id,
                latitude: obs.latitude!,
                longitude: obs.longitude!,
                observation: obs,
              ))
          .toList();

      // Calculate center position
      MapPosition? center;
      if (markers.isNotEmpty) {
        center = _calculateCenter(markers);
      }

      emit(MapLoaded(
        markers: markers,
        center: center,
        clusteringEnabled: true,
        speciesFilter: event.speciesFilter,
        locationFilter: event.locationFilter,
        startDate: event.startDate,
        endDate: event.endDate,
      ));
    } catch (e) {
      print('[MapBloc] Error filtering map observations: $e');
      emit(MapError(e.toString()));
    }
  }

  /// Handle clearing all map filters
  Future<void> _onClearMapFilters(
    ClearMapFilters event,
    Emitter<MapState> emit,
  ) async {
    print('[MapBloc] Clearing map filters');
    add(const LoadMapObservations());
  }

  /// Calculate the center position from a list of markers
  MapPosition _calculateCenter(List<MapMarker> markers) {
    if (markers.isEmpty) {
      return const MapPosition(latitude: 0, longitude: 0);
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final marker in markers) {
      totalLat += marker.latitude;
      totalLng += marker.longitude;
    }

    return MapPosition(
      latitude: totalLat / markers.length,
      longitude: totalLng / markers.length,
      zoom: 10.0,
    );
  }
}
