import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bird_watching_mobile/presentation/blocs/observation/observation_bloc.dart';
import 'package:bird_watching_mobile/presentation/blocs/observation/observation_event.dart';
import 'package:bird_watching_mobile/presentation/blocs/observation/observation_state.dart';
import 'package:bird_watching_mobile/data/repositories/observation_repository.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';

import 'observation_bloc_test.mocks.dart';

@GenerateMocks([ObservationRepository, ConnectivityService])
void main() {
  late MockObservationRepository mockObservationRepository;
  late MockConnectivityService mockConnectivityService;
  late ObservationBloc observationBloc;

  setUp(() {
    mockObservationRepository = MockObservationRepository();
    mockConnectivityService = MockConnectivityService();
    
    // Default connectivity stream
    when(mockConnectivityService.connectivityStream)
        .thenAnswer((_) => Stream.value(true));
    
    observationBloc = ObservationBloc(
      observationRepository: mockObservationRepository,
      connectivityService: mockConnectivityService,
    );
  });

  tearDown(() {
    observationBloc.close();
  });

  group('ObservationBloc', () {
    final testObservation = Observation(
      id: 'test-id',
      userId: 'user-id',
      speciesName: 'Blue Jay',
      observationDate: DateTime.now(),
      location: 'Test Location',
      latitude: 40.7128,
      longitude: -74.0060,
      isShared: false,
      pendingSync: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final offlineObservation = testObservation.copyWith(
      id: 'offline-id',
      pendingSync: true,
    );

    test('initial state is ObservationInitial', () {
      expect(observationBloc.state, equals(const ObservationInitial()));
    });

    group('LoadObservations', () {
      test('emits [ObservationsLoading, ObservationsLoaded] when loading succeeds',
          () async {
        // Arrange
        when(mockObservationRepository.getObservations(
          forceRefresh: false,
          userId: null,
        )).thenAnswer((_) async => [testObservation]);
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => []);
        when(mockConnectivityService.isConnected())
            .thenAnswer((_) async => true);

        // Assert
        expectLater(
          observationBloc.stream,
          emitsInOrder([
            const ObservationsLoading(),
            isA<ObservationsLoaded>()
                .having((s) => s.observations.length, 'observations length', 1)
                .having((s) => s.pendingSyncCount, 'pendingSyncCount', 0)
                .having((s) => s.isOffline, 'isOffline', false),
          ]),
        );

        // Act
        observationBloc.add(const LoadObservations());
      });

      test('handles offline mode correctly', () async {
        // Arrange
        when(mockObservationRepository.getObservations(
          forceRefresh: false,
          userId: null,
        )).thenAnswer((_) async => [testObservation, offlineObservation]);
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => [offlineObservation]);
        when(mockConnectivityService.isConnected())
            .thenAnswer((_) async => false);

        // Assert
        expectLater(
          observationBloc.stream,
          emitsInOrder([
            const ObservationsLoading(),
            isA<ObservationsLoaded>()
                .having((s) => s.observations.length, 'observations length', 2)
                .having((s) => s.pendingSyncCount, 'pendingSyncCount', 1)
                .having((s) => s.isOffline, 'isOffline', true),
          ]),
        );

        // Act
        observationBloc.add(const LoadObservations());
      });
    });

    group('CreateObservation', () {
      test('emits [ObservationCreating, ObservationCreated] when creation succeeds',
          () async {
        // Arrange
        when(mockObservationRepository.createObservation(testObservation))
            .thenAnswer((_) async => testObservation);
        when(mockObservationRepository.getObservations(
          forceRefresh: false,
          userId: null,
        )).thenAnswer((_) async => [testObservation]);
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => []);
        when(mockConnectivityService.isConnected())
            .thenAnswer((_) async => true);

        // Assert
        expectLater(
          observationBloc.stream,
          emitsInOrder([
            const ObservationCreating(),
            isA<ObservationCreated>(),
            const ObservationsLoading(),
            isA<ObservationsLoaded>(),
          ]),
        );

        // Act
        observationBloc.add(CreateObservation(testObservation));
      });

      test('creates observation offline with pendingSync flag', () async {
        // Arrange
        when(mockObservationRepository.createObservation(testObservation))
            .thenAnswer((_) async => offlineObservation);
        when(mockObservationRepository.getObservations(
          forceRefresh: false,
          userId: null,
        )).thenAnswer((_) async => [offlineObservation]);
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => [offlineObservation]);
        when(mockConnectivityService.isConnected())
            .thenAnswer((_) async => false);

        // Assert
        expectLater(
          observationBloc.stream,
          emitsInOrder([
            const ObservationCreating(),
            isA<ObservationCreated>()
                .having((s) => s.observation.pendingSync, 'pendingSync', true),
            const ObservationsLoading(),
            isA<ObservationsLoaded>()
                .having((s) => s.pendingSyncCount, 'pendingSyncCount', 1),
          ]),
        );

        // Act
        observationBloc.add(CreateObservation(testObservation));
      });
    });

    group('SyncPendingObservations', () {
      test('syncs pending observations when connectivity is restored', () async {
        // Arrange
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => [offlineObservation]);
        when(mockObservationRepository.syncObservation(offlineObservation))
            .thenAnswer((_) async => {});
        when(mockObservationRepository.getObservations(
          forceRefresh: true,
          userId: null,
        )).thenAnswer((_) async => [testObservation]);
        when(mockConnectivityService.isConnected())
            .thenAnswer((_) async => true);

        // Act
        observationBloc.add(const SyncPendingObservations());

        // Wait for sync to complete
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify sync was called
        verify(mockObservationRepository.syncObservation(offlineObservation))
            .called(1);
      });

      test('does not sync when no pending observations', () async {
        // Arrange
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => []);

        // Act
        observationBloc.add(const SyncPendingObservations());

        // Wait
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify sync was not called
        verifyNever(mockObservationRepository.syncObservation(any));
      });
    });

    group('SearchObservations', () {
      test('filters observations by search query', () async {
        // Arrange
        when(mockObservationRepository.searchObservations('Blue', userId: null))
            .thenAnswer((_) async => [testObservation]);
        when(mockObservationRepository.getPendingSyncObservations())
            .thenAnswer((_) async => []);
        when(mockConnectivityService.isConnected())
            .thenAnswer((_) async => true);

        // Assert
        expectLater(
          observationBloc.stream,
          emitsInOrder([
            const ObservationsLoading(),
            isA<ObservationsLoaded>()
                .having((s) => s.observations.length, 'observations length', 1),
          ]),
        );

        // Act
        observationBloc.add(const SearchObservations(query: 'Blue'));
      });
    });
  });
}
