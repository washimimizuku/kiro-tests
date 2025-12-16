import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/trip_repository.dart';
import 'trip_event.dart';
import 'trip_state.dart';

/// BLoC for managing trip state
/// Handles CRUD operations for trips and trip-observation associations
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _tripRepository;

  TripBloc({
    required TripRepository tripRepository,
  })  : _tripRepository = tripRepository,
        super(const TripInitial()) {
    on<LoadTrips>(_onLoadTrips);
    on<LoadTripById>(_onLoadTripById);
    on<CreateTrip>(_onCreateTrip);
    on<UpdateTrip>(_onUpdateTrip);
    on<DeleteTrip>(_onDeleteTrip);
    on<LoadTripObservations>(_onLoadTripObservations);
    on<AddObservationToTrip>(_onAddObservationToTrip);
    on<RemoveObservationFromTrip>(_onRemoveObservationFromTrip);
  }

  /// Handle loading all trips
  Future<void> _onLoadTrips(
    LoadTrips event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripsLoading());

    try {
      print('[TripBloc] Loading trips (forceRefresh: ${event.forceRefresh})');
      
      final trips = await _tripRepository.getTrips(
        forceRefresh: event.forceRefresh,
        userId: event.userId,
      );

      print('[TripBloc] Loaded ${trips.length} trips');

      emit(TripsLoaded(trips));
    } catch (e) {
      print('[TripBloc] Error loading trips: $e');
      emit(TripError(e.toString()));
    }
  }

  /// Handle loading a specific trip by ID
  Future<void> _onLoadTripById(
    LoadTripById event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripLoading());

    try {
      print('[TripBloc] Loading trip: ${event.tripId}');
      
      final trip = await _tripRepository.getTripById(event.tripId);

      if (trip == null) {
        emit(TripError('Trip not found: ${event.tripId}'));
        return;
      }

      print('[TripBloc] Loaded trip: ${trip.name}');

      emit(TripLoaded(trip));
    } catch (e) {
      print('[TripBloc] Error loading trip: $e');
      emit(TripError(e.toString()));
    }
  }

  /// Handle creating a new trip
  Future<void> _onCreateTrip(
    CreateTrip event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripCreating());

    try {
      print('[TripBloc] Creating trip: ${event.trip.name}');
      
      final createdTrip = await _tripRepository.createTrip(event.trip);

      print('[TripBloc] Trip created: ${createdTrip.id}');

      emit(TripCreated(createdTrip));

      // Reload trips to update the list
      add(const LoadTrips());
    } catch (e) {
      print('[TripBloc] Error creating trip: $e');
      emit(TripError(e.toString()));
      
      // Return to previous state if available
      add(const LoadTrips());
    }
  }

  /// Handle updating an existing trip
  Future<void> _onUpdateTrip(
    UpdateTrip event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripUpdating());

    try {
      print('[TripBloc] Updating trip: ${event.trip.id}');
      
      final updatedTrip = await _tripRepository.updateTrip(event.trip);

      print('[TripBloc] Trip updated: ${updatedTrip.id}');

      emit(TripUpdated(updatedTrip));

      // Reload trips to update the list
      add(const LoadTrips());
    } catch (e) {
      print('[TripBloc] Error updating trip: $e');
      emit(TripError(e.toString()));
      
      // Return to previous state if available
      add(const LoadTrips());
    }
  }

  /// Handle deleting a trip
  Future<void> _onDeleteTrip(
    DeleteTrip event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripDeleting());

    try {
      print('[TripBloc] Deleting trip: ${event.tripId}');
      
      await _tripRepository.deleteTrip(event.tripId);

      print('[TripBloc] Trip deleted: ${event.tripId}');

      emit(TripDeleted(event.tripId));

      // Reload trips to update the list
      add(const LoadTrips());
    } catch (e) {
      print('[TripBloc] Error deleting trip: $e');
      emit(TripError(e.toString()));
      
      // Return to previous state if available
      add(const LoadTrips());
    }
  }

  /// Handle loading observations for a specific trip
  Future<void> _onLoadTripObservations(
    LoadTripObservations event,
    Emitter<TripState> emit,
  ) async {
    emit(const TripObservationsLoading());

    try {
      print('[TripBloc] Loading observations for trip: ${event.tripId}');
      
      final observations = await _tripRepository.getTripObservations(event.tripId);

      print('[TripBloc] Loaded ${observations.length} observations for trip ${event.tripId}');

      emit(TripObservationsLoaded(
        tripId: event.tripId,
        observations: observations,
      ));
    } catch (e) {
      print('[TripBloc] Error loading trip observations: $e');
      emit(TripError(e.toString()));
    }
  }

  /// Handle adding an observation to a trip
  Future<void> _onAddObservationToTrip(
    AddObservationToTrip event,
    Emitter<TripState> emit,
  ) async {
    try {
      print('[TripBloc] Adding observation ${event.observationId} to trip ${event.tripId}');
      
      await _tripRepository.addObservationToTrip(
        event.tripId,
        event.observationId,
      );

      print('[TripBloc] Observation added to trip successfully');

      // Reload trip observations to update the list
      add(LoadTripObservations(event.tripId));
    } catch (e) {
      print('[TripBloc] Error adding observation to trip: $e');
      emit(TripError(e.toString()));
    }
  }

  /// Handle removing an observation from a trip
  Future<void> _onRemoveObservationFromTrip(
    RemoveObservationFromTrip event,
    Emitter<TripState> emit,
  ) async {
    try {
      print('[TripBloc] Removing observation ${event.observationId} from trip ${event.tripId}');
      
      await _tripRepository.removeObservationFromTrip(
        event.tripId,
        event.observationId,
      );

      print('[TripBloc] Observation removed from trip successfully');

      // Reload trip observations to update the list
      add(LoadTripObservations(event.tripId));
    } catch (e) {
      print('[TripBloc] Error removing observation from trip: $e');
      emit(TripError(e.toString()));
    }
  }
}
