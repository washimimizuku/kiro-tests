import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../models/observation.dart';
import '../models/sync_result.dart';
import '../repositories/observation_repository.dart';
import 'connectivity_service.dart';
import '../../core/constants/app_constants.dart';

/// Progress information for sync operations
class SyncProgress {
  final int current;
  final int total;
  final String? currentObservationId;
  final bool isComplete;
  final SyncResult? result;

  const SyncProgress({
    required this.current,
    required this.total,
    this.currentObservationId,
    this.isComplete = false,
    this.result,
  });

  double get progress => total > 0 ? current / total : 0.0;

  @override
  String toString() {
    return 'SyncProgress(current: $current, total: $total, '
        'currentObservationId: $currentObservationId, isComplete: $isComplete)';
  }
}

/// Service for synchronizing offline observations with the backend
class SyncService {
  final ObservationRepository _observationRepo;
  final ConnectivityService _connectivity;

  final _syncProgressController = BehaviorSubject<SyncProgress>();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;

  SyncService({
    required ObservationRepository observationRepository,
    required ConnectivityService connectivity,
  })  : _observationRepo = observationRepository,
        _connectivity = connectivity;

  /// Stream of sync progress updates
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;

  /// Get current sync progress
  SyncProgress? get currentProgress => _syncProgressController.valueOrNull;

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Enable or disable auto-sync
  set autoSyncEnabled(bool enabled) {
    _autoSyncEnabled = enabled;
    if (enabled) {
      startAutoSync();
    } else {
      stopAutoSync();
    }
  }

  /// Get auto-sync status
  bool get autoSyncEnabled => _autoSyncEnabled;

  /// Start automatic sync monitoring
  /// Syncs when connectivity is restored and periodically
  /// This runs in the foreground and respects the auto-sync setting
  void startAutoSync() {
    if (!_autoSyncEnabled) return;

    print('[SyncService] Starting auto-sync');

    // Listen for connectivity changes
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing && _autoSyncEnabled) {
        print('[SyncService] Connectivity restored, triggering sync');
        syncPendingObservations();
      }
    });

    // Set up periodic sync (runs while app is in foreground)
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(AppConstants.syncInterval, (_) {
      if (!_isSyncing && _autoSyncEnabled) {
        _checkAndSync();
      }
    });
  }

  /// Stop automatic sync monitoring
  void stopAutoSync() {
    print('[SyncService] Stopping auto-sync');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Check connectivity and sync if online
  Future<void> _checkAndSync() async {
    final isConnected = await _connectivity.isConnected();
    if (isConnected) {
      await syncPendingObservations();
    }
  }

  /// Sync all pending observations to the backend
  /// Returns SyncResult with success/failure counts
  Future<SyncResult> syncPendingObservations() async {
    if (_isSyncing) {
      print('[SyncService] Sync already in progress, skipping');
      return SyncResult.empty();
    }

    _isSyncing = true;

    try {
      // Check connectivity
      final isConnected = await _connectivity.isConnected();
      if (!isConnected) {
        print('[SyncService] No internet connection, cannot sync');
        _isSyncing = false;
        return SyncResult.empty();
      }

      // Get pending observations
      final pendingObservations = await _observationRepo.getPendingSyncObservations();

      if (pendingObservations.isEmpty) {
        print('[SyncService] No pending observations to sync');
        _isSyncing = false;
        _syncProgressController.add(SyncProgress(
          current: 0,
          total: 0,
          isComplete: true,
          result: SyncResult.empty(),
        ));
        return SyncResult.empty();
      }

      print('[SyncService] Syncing ${pendingObservations.length} pending observations');

      // Sort observations: prioritize those with photos
      final sortedObservations = _prioritizeObservations(pendingObservations);

      // Sync each observation
      int successful = 0;
      int failed = 0;
      final List<String> failedIds = [];
      final List<String> errors = [];

      for (int i = 0; i < sortedObservations.length; i++) {
        final observation = sortedObservations[i];

        // Emit progress
        _syncProgressController.add(SyncProgress(
          current: i,
          total: sortedObservations.length,
          currentObservationId: observation.id,
        ));

        try {
          await _syncObservationWithRetry(observation);
          successful++;
          print('[SyncService] Successfully synced observation: ${observation.id}');
        } catch (e) {
          failed++;
          failedIds.add(observation.id);
          errors.add(e.toString());
          print('[SyncService] Failed to sync observation ${observation.id}: $e');
        }
      }

      final result = SyncResult.partial(
        totalAttempted: sortedObservations.length,
        successful: successful,
        failed: failed,
        failedIds: failedIds,
        errors: errors,
      );

      // Emit completion
      _syncProgressController.add(SyncProgress(
        current: sortedObservations.length,
        total: sortedObservations.length,
        isComplete: true,
        result: result,
      ));

      print('[SyncService] Sync complete: $successful successful, $failed failed');
      return result;
    } catch (e) {
      print('[SyncService Error] Sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single observation with exponential backoff retry
  Future<void> _syncObservationWithRetry(
    Observation observation, {
    int maxAttempts = AppConstants.maxRetryAttempts,
  }) async {
    int attempt = 0;
    Duration delay = AppConstants.retryDelay;

    while (attempt < maxAttempts) {
      try {
        await _observationRepo.syncObservation(observation);
        return; // Success
      } catch (e) {
        attempt++;

        if (attempt >= maxAttempts) {
          print('[SyncService] Max retry attempts reached for observation ${observation.id}');
          rethrow;
        }

        print('[SyncService] Retry attempt $attempt/$maxAttempts for observation ${observation.id} after ${delay.inSeconds}s');
        await Future.delayed(delay);

        // Exponential backoff
        delay *= 2;
      }
    }
  }

  /// Prioritize observations with photos for syncing
  List<Observation> _prioritizeObservations(List<Observation> observations) {
    final withPhotos = <Observation>[];
    final withoutPhotos = <Observation>[];

    for (final observation in observations) {
      if (observation.photoUrl != null || observation.localPhotoPath != null) {
        withPhotos.add(observation);
      } else {
        withoutPhotos.add(observation);
      }
    }

    // Return observations with photos first, then without
    return [...withPhotos, ...withoutPhotos];
  }

  /// Manually trigger sync for a single observation
  Future<void> syncObservation(Observation observation) async {
    try {
      final isConnected = await _connectivity.isConnected();
      if (!isConnected) {
        throw Exception('No internet connection');
      }

      await _syncObservationWithRetry(observation);
      print('[SyncService] Successfully synced single observation: ${observation.id}');
    } catch (e) {
      print('[SyncService Error] Failed to sync observation: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
    _syncProgressController.close();
    print('[SyncService] Disposed');
  }
}
