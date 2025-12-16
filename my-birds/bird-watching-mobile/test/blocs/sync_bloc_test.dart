import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bird_watching_mobile/presentation/blocs/sync/sync.dart';
import 'package:bird_watching_mobile/data/services/sync_service.dart';
import 'package:bird_watching_mobile/data/models/sync_result.dart';

import 'sync_bloc_test.mocks.dart';

@GenerateMocks([SyncService])
void main() {
  late MockSyncService mockSyncService;
  late SyncBloc syncBloc;

  setUp(() {
    mockSyncService = MockSyncService();
    
    // Default sync progress stream
    when(mockSyncService.syncProgressStream)
        .thenAnswer((_) => Stream.empty());
    when(mockSyncService.autoSyncEnabled).thenReturn(true);
    when(mockSyncService.isSyncing).thenReturn(false);
    
    syncBloc = SyncBloc(syncService: mockSyncService);
  });

  tearDown(() {
    syncBloc.close();
  });

  group('SyncBloc', () {
    test('initial state is SyncIdle with autoSyncEnabled', () {
      expect(syncBloc.state, equals(const SyncIdle(autoSyncEnabled: true)));
    });

    group('StartSync', () {
      test('emits [Syncing] when sync starts', () async {
        // Arrange
        when(mockSyncService.isSyncing).thenReturn(false);
        when(mockSyncService.syncPendingObservations())
            .thenAnswer((_) async => SyncResult.empty());

        // Assert
        expectLater(
          syncBloc.stream,
          emits(isA<Syncing>()),
        );

        // Act
        syncBloc.add(const StartSync());
      });

      test('does not start sync if already syncing', () async {
        // Arrange
        when(mockSyncService.isSyncing).thenReturn(true);

        // Act
        syncBloc.add(const StartSync());

        // Wait
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify sync was not called
        verifyNever(mockSyncService.syncPendingObservations());
      });

      test('handles sync errors gracefully', () async {
        // Arrange
        when(mockSyncService.isSyncing).thenReturn(false);
        when(mockSyncService.syncPendingObservations())
            .thenThrow(Exception('Sync failed'));

        // Assert
        expectLater(
          syncBloc.stream,
          emitsInOrder([
            isA<Syncing>(),
            isA<SyncError>(),
            isA<SyncIdle>(),
          ]),
        );

        // Act
        syncBloc.add(const StartSync());
      });
    });

    group('UpdateSyncProgress', () {
      test('updates progress during sync', () async {
        // Assert
        expectLater(
          syncBloc.stream,
          emits(isA<Syncing>()
              .having((s) => s.current, 'current', 5)
              .having((s) => s.total, 'total', 10)
              .having((s) => s.progress, 'progress', 0.5)),
        );

        // Act
        syncBloc.add(const UpdateSyncProgress(current: 5, total: 10));
      });
    });

    group('SetAutoSync', () {
      test('enables auto-sync', () async {
        // Arrange
        when(mockSyncService.autoSyncEnabled).thenReturn(true);

        // Assert
        expectLater(
          syncBloc.stream,
          emits(const SyncIdle(autoSyncEnabled: true)),
        );

        // Act
        syncBloc.add(const SetAutoSync(true));

        // Wait
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify
        verify(mockSyncService.autoSyncEnabled = true).called(1);
      });

      test('disables auto-sync', () async {
        // Arrange
        when(mockSyncService.autoSyncEnabled).thenReturn(false);

        // Assert
        expectLater(
          syncBloc.stream,
          emits(const SyncIdle(autoSyncEnabled: false)),
        );

        // Act
        syncBloc.add(const SetAutoSync(false));

        // Wait
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify
        verify(mockSyncService.autoSyncEnabled = false).called(1);
      });
    });

    group('Sync retry logic', () {
      test('handles partial sync results with failures', () async {
        // Arrange
        final partialResult = SyncResult.partial(
          totalAttempted: 5,
          successful: 3,
          failed: 2,
          failedIds: ['id1', 'id2'],
          errors: ['Error 1', 'Error 2'],
        );

        when(mockSyncService.isSyncing).thenReturn(false);
        when(mockSyncService.syncPendingObservations())
            .thenAnswer((_) async => partialResult);

        // Act
        syncBloc.add(const StartSync());

        // Wait for sync to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify sync was called
        verify(mockSyncService.syncPendingObservations()).called(1);
      });
    });
  });
}
