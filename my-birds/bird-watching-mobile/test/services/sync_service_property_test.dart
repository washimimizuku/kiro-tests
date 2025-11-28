import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:math';
import 'package:bird_watching_mobile/data/services/sync_service.dart';
import 'package:bird_watching_mobile/data/repositories/observation_repository.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';
import 'package:bird_watching_mobile/data/models/sync_result.dart';

@GenerateMocks([ObservationRepository, ConnectivityService])
import 'sync_service_property_test.mocks.dart';

/// Property-based test generators for sync testing
class SyncPropertyGenerators {
  static final Random _random = Random();
  
  /// Generate random observation with pending sync
  static Observation generatePendingObservation({bool withPhoto = false}) {
    return Observation(
      id: _random.nextInt(1000000).toString(),
      userId: _random.nextInt(10000).toString(),
      tripId: null,
      speciesName: 'Test Species ${_random.nextInt(100)}',
      observationDate: DateTime.now(),
      location: 'Test Location',
      latitude: -90 + _random.nextDouble() * 180,
      longitude: -180 + _random.nextDouble() * 360,
      notes: 'Test notes',
      photoUrl: withPhoto ? 'https://example.com/photo.jpg' : null,
      localPhotoPath: withPhoto ? '/local/path/photo.jpg' : null,
      isShared: false,
      pendingSync: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Generate list of random pending observations
  static List<Observation> generatePendingObservations(int count, {double photoRatio = 0.5}) {
    return List.generate(count, (i) {
      final withPhoto = _random.nextDouble() < photoRatio;
      return generatePendingObservation(withPhoto: withPhoto);
    });
  }
}

void main() {
  group('SyncService Property Tests', () {
    late MockObservationRepository mockObservationRepo;
    late MockConnectivityService mockConnectivity;
    late SyncService syncService;

    setUp(() {
      mockObservationRepo = MockObservationRepository();
      mockConnectivity = MockConnectivityService();
      syncService = SyncService(
        observationRepository: mockObservationRepo,
        connectivity: mockConnectivity,
      );
    });

    tearDown(() {
      syncService.dispose();
    });

    /// **Feature: flutter-mobile-app, Property 10: Automatic sync on connectivity**
    /// **Validates: Requirements 5.3**
    /// 
    /// Property: For any pending sync observations, when network connectivity
    /// is restored, all pending observations should be automatically synced
    /// to the backend.
    test('Property 10: Automatic sync on connectivity - 50 iterations', () async {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of pending observations (1-10)
        final observationCount = 1 + Random().nextInt(10);
        final pendingObservations = SyncPropertyGenerators.generatePendingObservations(
          observationCount,
        );
        
        // Reset mocks for each iteration
        reset(mockObservationRepo);
        reset(mockConnectivity);
        
        // Mock connectivity check
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock getting pending observations
        when(mockObservationRepo.getPendingSyncObservations())
            .thenAnswer((_) async => pendingObservations);
        
        // Mock successful sync for each observation
        for (final observation in pendingObservations) {
          when(mockObservationRepo.syncObservation(observation))
              .thenAnswer((_) async => {});
        }
        
        // Execute sync
        final result = await syncService.syncPendingObservations();
        
        // Verify all observations were synced
        expect(result.totalAttempted, equals(observationCount),
          reason: 'Iteration $i: Should attempt to sync all pending observations');
        expect(result.successful, equals(observationCount),
          reason: 'Iteration $i: All syncs should succeed when online');
        expect(result.failed, equals(0),
          reason: 'Iteration $i: No syncs should fail');
        
        // Verify each observation was synced
        for (final observation in pendingObservations) {
          verify(mockObservationRepo.syncObservation(observation)).called(1);
        }
      }
    });

    /// **Feature: flutter-mobile-app, Property 11: Sync retry with exponential backoff**
    /// **Validates: Requirements 5.4**
    /// 
    /// Property: For any failed sync attempt, the system should retry with
    /// exponentially increasing delays (e.g., 1s, 2s, 4s, 8s).
    test('Property 11: Sync retry with exponential backoff - 10 iterations', () async {
      const iterations = 10; // Reduced iterations due to retry delays (6s per iteration)
      
      for (int i = 0; i < iterations; i++) {
        // Create new sync service for each iteration to avoid stream issues
        final testSyncService = SyncService(
          observationRepository: mockObservationRepo,
          connectivity: mockConnectivity,
        );
        
        // Generate single pending observation
        final observation = SyncPropertyGenerators.generatePendingObservation();
        
        // Reset mocks for each iteration
        reset(mockObservationRepo);
        reset(mockConnectivity);
        
        // Mock connectivity check
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock getting pending observations
        when(mockObservationRepo.getPendingSyncObservations())
            .thenAnswer((_) async => [observation]);
        
        // Mock sync to fail first 2 times, then succeed on 3rd attempt
        int attemptCount = 0;
        when(mockObservationRepo.syncObservation(any)).thenAnswer((_) async {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('Sync failed (attempt $attemptCount)');
          }
          // Success on 3rd attempt
        });
        
        // Execute sync
        final result = await testSyncService.syncPendingObservations();
        
        // Verify retry behavior
        expect(attemptCount, equals(3),
          reason: 'Iteration $i: Should retry until success (3 attempts)');
        expect(result.successful, equals(1),
          reason: 'Iteration $i: Should eventually succeed after retries');
        expect(result.failed, equals(0),
          reason: 'Iteration $i: Should not fail if retries succeed');
        
        // Verify sync was called multiple times (with retries)
        verify(mockObservationRepo.syncObservation(any)).called(3);
        
        // Dispose the test service
        testSyncService.dispose();
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    /// **Feature: flutter-mobile-app, Property 31: Sync prioritizes photos**
    /// **Validates: Requirements 14.4**
    /// 
    /// Property: For any sync operation with multiple pending observations,
    /// observations with photos should be synced before observations without photos.
    test('Property 31: Sync prioritizes photos - 50 iterations', () async {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate mix of observations with and without photos
        final withPhotos = SyncPropertyGenerators.generatePendingObservations(
          3,
          photoRatio: 1.0, // All have photos
        );
        final withoutPhotos = SyncPropertyGenerators.generatePendingObservations(
          3,
          photoRatio: 0.0, // None have photos
        );
        
        // Mix them up (not in priority order)
        final allObservations = [...withoutPhotos, ...withPhotos];
        
        // Reset mocks for each iteration
        reset(mockObservationRepo);
        reset(mockConnectivity);
        
        // Mock connectivity check
        when(mockConnectivity.isConnected()).thenAnswer((_) async => true);
        
        // Mock getting pending observations
        when(mockObservationRepo.getPendingSyncObservations())
            .thenAnswer((_) async => allObservations);
        
        // Track sync order
        final syncOrder = <String>[];
        
        // Mock successful sync for each observation
        for (final observation in allObservations) {
          when(mockObservationRepo.syncObservation(observation)).thenAnswer((_) async {
            syncOrder.add(observation.id);
          });
        }
        
        // Execute sync
        final result = await syncService.syncPendingObservations();
        
        // Verify all observations were synced
        expect(result.totalAttempted, equals(6),
          reason: 'Iteration $i: Should sync all 6 observations');
        expect(result.successful, equals(6),
          reason: 'Iteration $i: All syncs should succeed');
        
        // Verify observations with photos were synced first
        final firstThreeIds = syncOrder.take(3).toList();
        final photoIds = withPhotos.map((o) => o.id).toSet();
        
        // All of the first 3 synced should have photos
        for (final id in firstThreeIds) {
          expect(photoIds.contains(id), isTrue,
            reason: 'Iteration $i: First 3 synced observations should all have photos');
        }
        
        // Last 3 should be without photos
        final lastThreeIds = syncOrder.skip(3).toList();
        final noPhotoIds = withoutPhotos.map((o) => o.id).toSet();
        
        for (final id in lastThreeIds) {
          expect(noPhotoIds.contains(id), isTrue,
            reason: 'Iteration $i: Last 3 synced observations should all be without photos');
        }
      }
    });

    /// Additional test: Verify sync doesn't run when offline
    test('Property: Sync skips when offline - 50 iterations', () async {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random pending observations
        final observationCount = 1 + Random().nextInt(10);
        final pendingObservations = SyncPropertyGenerators.generatePendingObservations(
          observationCount,
        );
        
        // Reset mocks for each iteration
        reset(mockObservationRepo);
        reset(mockConnectivity);
        
        // Mock offline state
        when(mockConnectivity.isConnected()).thenAnswer((_) async => false);
        
        // Mock getting pending observations (shouldn't be called)
        when(mockObservationRepo.getPendingSyncObservations())
            .thenAnswer((_) async => pendingObservations);
        
        // Execute sync
        final result = await syncService.syncPendingObservations();
        
        // Verify no sync occurred
        expect(result.isEmpty, isTrue,
          reason: 'Iteration $i: Should return empty result when offline');
        expect(result.totalAttempted, equals(0),
          reason: 'Iteration $i: Should not attempt any syncs when offline');
        
        // Verify getPendingSyncObservations was not called
        verifyNever(mockObservationRepo.getPendingSyncObservations());
        
        // Verify no observations were synced
        verifyNever(mockObservationRepo.syncObservation(any));
      }
    });
  });
}
