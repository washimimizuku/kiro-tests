import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/observation_repository.dart';
import '../../../data/services/connectivity_service.dart';
import 'observation_event.dart';
import 'observation_state.dart';

/// BLoC for managing observation state
/// Handles CRUD operations, offline mode, and sync status tracking
class ObservationBloc extends Bloc<ObservationEvent, ObservationState> {
  final ObservationRepository _observationRepository;
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  ObservationBloc({
    required ObservationRepository observationRepository,
    required ConnectivityService connectivityService,
  })  : _observationRepository = observationRepository,
        _connectivityService = connectivityService,
        super(const ObservationInitial()) {
    on<LoadObservations>(_onLoadObservations);
    on<CreateObservation>(_onCreateObservation);
    on<UpdateObservation>(_onUpdateObservation);
    on<DeleteObservation>(_onDeleteObservation);
    on<SyncPendingObservations>(_onSyncPendingObservations);
    on<SearchObservations>(_onSearchObservations);
    on<FilterObservationsByDateRange>(_onFilterObservationsByDateRange);
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
    on<UpdateConnectivityStatus>(_onUpdateConnectivityStatus);
    on<RefreshPendingSyncCount>(_onRefreshPendingSyncCount);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        add(UpdateConnectivityStatus(isConnected));
        
        // Auto-sync when connectivity is restored
        if (isConnected) {
          add(const SyncPendingObservations());
        }
      },
    );
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  /// Handle loading observations
  Future<void> _onLoadObservations(
    LoadObservations event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationsLoading());

    try {
      print('[ObservationBloc] Loading observations (forceRefresh: ${event.forceRefresh})');
      
      final observations = await _observationRepository.getObservations(
        forceRefresh: event.forceRefresh,
        userId: event.userId,
      );

      // Get pending sync count
      final pendingObservations = await _observationRepository.getPendingSyncObservations();
      final pendingSyncCount = pendingObservations.length;

      // Check connectivity status
      final isConnected = await _connectivityService.isConnected();

      print('[ObservationBloc] Loaded ${observations.length} observations, '
          '$pendingSyncCount pending sync');

      emit(ObservationsLoaded(
        observations: observations,
        pendingSyncCount: pendingSyncCount,
        isOffline: !isConnected,
      ));
    } catch (e) {
      print('[ObservationBloc] Error loading observations: $e');
      emit(ObservationError(e.toString()));
    }
  }

  /// Handle creating a new observation
  Future<void> _onCreateObservation(
    CreateObservation event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationCreating());

    try {
      print('[ObservationBloc] Creating observation: ${event.observation.speciesName}');
      
      final createdObservation = await _observationRepository.createObservation(
        event.observation,
      );

      print('[ObservationBloc] Observation created: ${createdObservation.id}, '
          'pendingSync: ${createdObservation.pendingSync}');

      emit(ObservationCreated(createdObservation));

      // Reload observations to update the list
      add(const LoadObservations());
    } catch (e) {
      print('[ObservationBloc] Error creating observation: $e');
      emit(ObservationError(e.toString()));
      
      // Return to previous state if available
      add(const LoadObservations());
    }
  }

  /// Handle updating an observation
  Future<void> _onUpdateObservation(
    UpdateObservation event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationUpdating());

    try {
      print('[ObservationBloc] Updating observation: ${event.observation.id}');
      
      final updatedObservation = await _observationRepository.updateObservation(
        event.observation,
      );

      print('[ObservationBloc] Observation updated: ${updatedObservation.id}, '
          'pendingSync: ${updatedObservation.pendingSync}');

      emit(ObservationUpdated(updatedObservation));

      // Reload observations to update the list
      add(const LoadObservations());
    } catch (e) {
      print('[ObservationBloc] Error updating observation: $e');
      emit(ObservationError(e.toString()));
      
      // Return to previous state if available
      add(const LoadObservations());
    }
  }

  /// Handle deleting an observation
  Future<void> _onDeleteObservation(
    DeleteObservation event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationDeleting());

    try {
      print('[ObservationBloc] Deleting observation: ${event.id}');
      
      await _observationRepository.deleteObservation(event.id);

      print('[ObservationBloc] Observation deleted: ${event.id}');

      emit(ObservationDeleted(event.id));

      // Reload observations to update the list
      add(const LoadObservations());
    } catch (e) {
      print('[ObservationBloc] Error deleting observation: $e');
      emit(ObservationError(e.toString()));
      
      // Return to previous state if available
      add(const LoadObservations());
    }
  }

  /// Handle syncing pending observations
  Future<void> _onSyncPendingObservations(
    SyncPendingObservations event,
    Emitter<ObservationState> emit,
  ) async {
    try {
      print('[ObservationBloc] Syncing pending observations');
      
      final pendingObservations = await _observationRepository.getPendingSyncObservations();
      
      if (pendingObservations.isEmpty) {
        print('[ObservationBloc] No pending observations to sync');
        return;
      }

      print('[ObservationBloc] Found ${pendingObservations.length} observations to sync');

      // Sync each observation
      int successCount = 0;
      int failCount = 0;

      for (final observation in pendingObservations) {
        try {
          await _observationRepository.syncObservation(observation);
          successCount++;
          print('[ObservationBloc] Synced observation: ${observation.id}');
        } catch (e) {
          failCount++;
          print('[ObservationBloc] Failed to sync observation ${observation.id}: $e');
        }
      }

      print('[ObservationBloc] Sync complete: $successCount succeeded, $failCount failed');

      // Reload observations to update sync status
      add(const LoadObservations(forceRefresh: true));
    } catch (e) {
      print('[ObservationBloc] Error syncing observations: $e');
      // Don't emit error state for sync failures, just log them
    }
  }

  /// Handle searching observations
  Future<void> _onSearchObservations(
    SearchObservations event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationsLoading());

    try {
      print('[ObservationBloc] Searching observations: ${event.query}');
      
      final observations = await _observationRepository.searchObservations(
        event.query,
        userId: event.userId,
      );

      // Get pending sync count
      final pendingObservations = await _observationRepository.getPendingSyncObservations();
      final pendingSyncCount = pendingObservations.length;

      // Check connectivity status
      final isConnected = await _connectivityService.isConnected();

      print('[ObservationBloc] Found ${observations.length} observations matching "${event.query}"');

      emit(ObservationsLoaded(
        observations: observations,
        pendingSyncCount: pendingSyncCount,
        isOffline: !isConnected,
      ));
    } catch (e) {
      print('[ObservationBloc] Error searching observations: $e');
      emit(ObservationError(e.toString()));
    }
  }

  /// Handle filtering observations by date range
  Future<void> _onFilterObservationsByDateRange(
    FilterObservationsByDateRange event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationsLoading());

    try {
      print('[ObservationBloc] Filtering observations by date range: '
          '${event.startDate} to ${event.endDate}');
      
      final observations = await _observationRepository.filterByDateRange(
        event.startDate,
        event.endDate,
        userId: event.userId,
      );

      // Get pending sync count
      final pendingObservations = await _observationRepository.getPendingSyncObservations();
      final pendingSyncCount = pendingObservations.length;

      // Check connectivity status
      final isConnected = await _connectivityService.isConnected();

      print('[ObservationBloc] Found ${observations.length} observations in date range');

      emit(ObservationsLoaded(
        observations: observations,
        pendingSyncCount: pendingSyncCount,
        isOffline: !isConnected,
      ));
    } catch (e) {
      print('[ObservationBloc] Error filtering observations: $e');
      emit(ObservationError(e.toString()));
    }
  }

  /// Handle applying multiple filters
  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<ObservationState> emit,
  ) async {
    emit(const ObservationsLoading());

    try {
      print('[ObservationBloc] Applying filters: species=${event.species}, '
          'location=${event.location}, dates=${event.startDate} to ${event.endDate}');
      
      // Get all observations first
      var observations = await _observationRepository.getObservations(
        userId: event.userId,
      );

      // Apply species filter
      if (event.species != null && event.species!.isNotEmpty) {
        observations = observations.where((obs) {
          return obs.speciesName.toLowerCase().contains(event.species!.toLowerCase());
        }).toList();
      }

      // Apply location filter
      if (event.location != null && event.location!.isNotEmpty) {
        observations = observations.where((obs) {
          return obs.location.toLowerCase().contains(event.location!.toLowerCase());
        }).toList();
      }

      // Apply date range filter
      if (event.startDate != null && event.endDate != null) {
        observations = observations.where((obs) {
          final obsDate = obs.observationDate;
          return obsDate.isAfter(event.startDate!.subtract(const Duration(days: 1))) &&
              obsDate.isBefore(event.endDate!.add(const Duration(days: 1)));
        }).toList();
      }

      // Get pending sync count
      final pendingObservations = await _observationRepository.getPendingSyncObservations();
      final pendingSyncCount = pendingObservations.length;

      // Check connectivity status
      final isConnected = await _connectivityService.isConnected();

      print('[ObservationBloc] Found ${observations.length} observations after filtering');

      emit(ObservationsLoaded(
        observations: observations,
        pendingSyncCount: pendingSyncCount,
        isOffline: !isConnected,
      ));
    } catch (e) {
      print('[ObservationBloc] Error applying filters: $e');
      emit(ObservationError(e.toString()));
    }
  }

  /// Handle clearing filters
  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<ObservationState> emit,
  ) async {
    print('[ObservationBloc] Clearing filters');
    add(LoadObservations(userId: event.userId));
  }

  /// Handle connectivity status updates
  Future<void> _onUpdateConnectivityStatus(
    UpdateConnectivityStatus event,
    Emitter<ObservationState> emit,
  ) async {
    print('[ObservationBloc] Connectivity status changed: ${event.isConnected}');
    
    // Update the current state with new connectivity status
    if (state is ObservationsLoaded) {
      final currentState = state as ObservationsLoaded;
      emit(currentState.copyWith(isOffline: !event.isConnected));
    }
  }

  /// Handle refreshing pending sync count
  Future<void> _onRefreshPendingSyncCount(
    RefreshPendingSyncCount event,
    Emitter<ObservationState> emit,
  ) async {
    if (state is ObservationsLoaded) {
      try {
        final pendingObservations = await _observationRepository.getPendingSyncObservations();
        final pendingSyncCount = pendingObservations.length;

        final currentState = state as ObservationsLoaded;
        emit(currentState.copyWith(pendingSyncCount: pendingSyncCount));
      } catch (e) {
        print('[ObservationBloc] Error refreshing pending sync count: $e');
      }
    }
  }
}
