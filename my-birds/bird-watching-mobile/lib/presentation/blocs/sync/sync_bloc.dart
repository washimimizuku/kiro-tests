import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/sync_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/models/sync_result.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// BLoC for managing sync state
/// Handles sync coordination and progress tracking
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  final NotificationService _notificationService;
  StreamSubscription<SyncProgress>? _syncProgressSubscription;

  SyncBloc({
    required SyncService syncService,
    required NotificationService notificationService,
  })  : _syncService = syncService,
        _notificationService = notificationService,
        super(SyncIdle(autoSyncEnabled: syncService.autoSyncEnabled)) {
    on<StartSync>(_onStartSync);
    on<SyncSingleObservation>(_onSyncSingleObservation);
    on<UpdateSyncProgress>(_onUpdateSyncProgress);
    on<SetAutoSync>(_onSetAutoSync);
    on<CancelSync>(_onCancelSync);

    // Listen to sync progress from the service
    _syncProgressSubscription = _syncService.syncProgressStream.listen(
      (progress) {
        if (progress.isComplete) {
          if (progress.result != null) {
            if (progress.result!.failed > 0) {
              add(UpdateSyncProgress(
                current: progress.current,
                total: progress.total,
              ));
              // Show error notification
              _notificationService.showSyncErrorNotification(
                'Sync completed with ${progress.result!.failed} failures',
                progress.result!.failed,
              );
              // Emit error state with partial results
              emit(SyncError(
                message: 'Sync completed with ${progress.result!.failed} failures',
                failed: progress.result!.failed,
                result: progress.result,
              ));
              // Return to idle after showing error
              emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
            } else {
              // Show success notification
              _notificationService.showSyncSuccessNotification(
                progress.result!.successful,
              );
              emit(SyncComplete(
                synced: progress.result!.successful,
                result: progress.result!,
              ));
              // Return to idle after completion
              emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
            }
          }
        } else {
          add(UpdateSyncProgress(
            current: progress.current,
            total: progress.total,
            currentObservationId: progress.currentObservationId,
          ));
        }
      },
      onError: (error) {
        print('[SyncBloc] Sync progress stream error: $error');
        emit(SyncError(message: error.toString()));
        emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
      },
    );
  }

  @override
  Future<void> close() {
    _syncProgressSubscription?.cancel();
    return super.close();
  }

  /// Handle starting sync
  Future<void> _onStartSync(
    StartSync event,
    Emitter<SyncState> emit,
  ) async {
    if (_syncService.isSyncing) {
      print('[SyncBloc] Sync already in progress');
      return;
    }

    try {
      print('[SyncBloc] Starting sync');
      
      // Emit initial syncing state
      emit(const Syncing(current: 0, total: 0));

      // Start sync (progress updates will come through the stream)
      await _syncService.syncPendingObservations();
      
      // Note: Final state will be emitted by the stream listener
    } catch (e) {
      print('[SyncBloc] Error starting sync: $e');
      emit(SyncError(message: e.toString()));
      emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
    }
  }

  /// Handle syncing a single observation
  Future<void> _onSyncSingleObservation(
    SyncSingleObservation event,
    Emitter<SyncState> emit,
  ) async {
    try {
      print('[SyncBloc] Syncing single observation: ${event.observation.id}');
      
      emit(Syncing(
        current: 0,
        total: 1,
        currentObservationId: event.observation.id,
      ));

      await _syncService.syncObservation(event.observation);

      print('[SyncBloc] Single observation synced successfully');
      
      final result = SyncResult(
        totalAttempted: 1,
        successful: 1,
        failed: 0,
        failedIds: const [],
        errors: const [],
      );
      
      emit(SyncComplete(
        synced: 1,
        result: result,
      ));

      // Return to idle
      emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
    } catch (e) {
      print('[SyncBloc] Error syncing single observation: $e');
      emit(SyncError(
        message: e.toString(),
        failed: 1,
      ));
      emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
    }
  }

  /// Handle sync progress updates
  Future<void> _onUpdateSyncProgress(
    UpdateSyncProgress event,
    Emitter<SyncState> emit,
  ) async {
    if (state is Syncing) {
      emit(Syncing(
        current: event.current,
        total: event.total,
        currentObservationId: event.currentObservationId,
      ));
    } else {
      // If not already syncing, start syncing state
      emit(Syncing(
        current: event.current,
        total: event.total,
        currentObservationId: event.currentObservationId,
      ));
    }
  }

  /// Handle enabling/disabling auto-sync
  Future<void> _onSetAutoSync(
    SetAutoSync event,
    Emitter<SyncState> emit,
  ) async {
    print('[SyncBloc] Setting auto-sync to: ${event.enabled}');
    
    _syncService.autoSyncEnabled = event.enabled;

    if (state is SyncIdle) {
      emit(SyncIdle(autoSyncEnabled: event.enabled));
    }
  }

  /// Handle canceling sync
  Future<void> _onCancelSync(
    CancelSync event,
    Emitter<SyncState> emit,
  ) async {
    print('[SyncBloc] Canceling sync');
    
    // Note: Current implementation doesn't support canceling mid-sync
    // This would require more complex state management in SyncService
    // For now, just return to idle state
    emit(SyncIdle(autoSyncEnabled: _syncService.autoSyncEnabled));
  }
}
