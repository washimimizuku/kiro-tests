import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bird_watching_mobile/presentation/screens/map/map_screen.dart';
import 'package:bird_watching_mobile/presentation/blocs/map/map_bloc.dart';
import 'package:bird_watching_mobile/presentation/blocs/map/map_state.dart';
import 'package:bird_watching_mobile/presentation/blocs/map/map_event.dart';
import 'package:bird_watching_mobile/presentation/blocs/auth/auth_bloc.dart';
import 'package:bird_watching_mobile/presentation/blocs/auth/auth_state.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';
import 'package:bird_watching_mobile/data/models/user.dart';
import 'package:bird_watching_mobile/data/repositories/observation_repository.dart';
import 'package:bird_watching_mobile/data/services/gps_service.dart';

import 'map_screen_widget_test.mocks.dart';

@GenerateMocks([ObservationRepository, GpsService, AuthBloc, MapBloc])
void main() {
  late MockObservationRepository mockObservationRepository;
  late MockGpsService mockGpsService;
  late MockAuthBloc mockAuthBloc;
  late MockMapBloc mockMapBloc;

  setUp(() {
    mockObservationRepository = MockObservationRepository();
    mockGpsService = MockGpsService();
    mockAuthBloc = MockAuthBloc();
    mockMapBloc = MockMapBloc();
  });

  /// Helper to create test observations
  Observation createTestObservation({
    required String id,
    required String speciesName,
    required double latitude,
    required double longitude,
    String? photoUrl,
  }) {
    return Observation(
      id: id,
      userId: 'user1',
      speciesName: speciesName,
      observationDate: DateTime.now(),
      location: 'Test Location',
      latitude: latitude,
      longitude: longitude,
      notes: 'Test notes',
      photoUrl: photoUrl,
      isShared: false,
      pendingSync: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Helper to wrap widgets with necessary providers
  Widget createTestWidget(Widget child) {
    // Mock auth state
    final user = User(
      id: 'user1',
      username: 'testuser',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );
    when(mockAuthBloc.state).thenReturn(Authenticated(user: user, token: 'token'));
    when(mockAuthBloc.stream).thenAnswer((_) => Stream.value(Authenticated(user: user, token: 'token')));

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<MapBloc>.value(value: mockMapBloc),
        ],
        child: child,
      ),
      routes: {
        '/observation-detail': (context) => const Scaffold(body: Text('Observation Detail')),
      },
    );
  }

  group('MapScreen Widget Tests', () {
    testWidgets('shows loading indicator when map is loading', (tester) async {
      // Mock loading state
      when(mockMapBloc.state).thenReturn(const MapLoading());
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(const MapLoading()));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when map fails to load', (tester) async {
      // Mock error state
      when(mockMapBloc.state).thenReturn(const MapError('Failed to load map'));
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(const MapError('Failed to load map')));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show error message
      expect(find.text('Error loading map'), findsOneWidget);
      expect(find.text('Failed to load map'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('renders map with markers when loaded', (tester) async {
      // Create test observations
      final observations = [
        createTestObservation(
          id: '1',
          speciesName: 'Robin',
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        createTestObservation(
          id: '2',
          speciesName: 'Sparrow',
          latitude: 37.7849,
          longitude: -122.4094,
        ),
      ];

      // Create markers
      final markers = observations
          .map((obs) => MapMarker(
                id: obs.id,
                latitude: obs.latitude!,
                longitude: obs.longitude!,
                observation: obs,
              ))
          .toList();

      // Mock loaded state
      final loadedState = MapLoaded(
        markers: markers,
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show Google Map
      expect(find.byType(GoogleMap), findsOneWidget);

      // Should show filter controls
      expect(find.text('2 observations'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Should show location button
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      // Should show clustering button
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
    });

    testWidgets('displays observation count correctly', (tester) async {
      // Create test observations
      final observations = List.generate(
        5,
        (i) => createTestObservation(
          id: '$i',
          speciesName: 'Bird $i',
          latitude: 37.7749 + i * 0.01,
          longitude: -122.4194 + i * 0.01,
        ),
      );

      final markers = observations
          .map((obs) => MapMarker(
                id: obs.id,
                latitude: obs.latitude!,
                longitude: obs.longitude!,
                observation: obs,
              ))
          .toList();

      final loadedState = MapLoaded(
        markers: markers,
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show correct count
      expect(find.text('5 observations'), findsOneWidget);
    });

    testWidgets('shows clustering enabled icon when clustering is on', (tester) async {
      final loadedState = MapLoaded(
        markers: const [],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show grid_on icon when clustering is enabled
      expect(find.byIcon(Icons.grid_on), findsOneWidget);
    });

    testWidgets('shows clustering disabled icon when clustering is off', (tester) async {
      final loadedState = MapLoaded(
        markers: const [],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: false,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show grid_off icon when clustering is disabled
      expect(find.byIcon(Icons.grid_off), findsOneWidget);
    });

    testWidgets('displays bottom sheet when observation is selected', (tester) async {
      final observation = createTestObservation(
        id: '1',
        speciesName: 'Robin',
        latitude: 37.7749,
        longitude: -122.4194,
        photoUrl: 'https://example.com/photo.jpg',
      );

      final marker = MapMarker(
        id: observation.id,
        latitude: observation.latitude!,
        longitude: observation.longitude!,
        observation: observation,
      );

      final loadedState = MapLoaded(
        markers: [marker],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
        selectedObservation: observation,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show bottom sheet with observation details
      expect(find.text('Robin'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'View Details'), findsOneWidget);

      // Should show close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows filter active indicator when filters are applied', (tester) async {
      final loadedState = MapLoaded(
        markers: const [],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
        speciesFilter: 'Robin',
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Should show filters active message
      expect(find.textContaining('Filters active'), findsOneWidget);

      // Should show clear filters button
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('opens filter dialog when filter button is tapped', (tester) async {
      final loadedState = MapLoaded(
        markers: const [],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should show filter dialog
      expect(find.text('Filter Observations'), findsOneWidget);
      expect(find.text('Species'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Apply'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Clear All'), findsOneWidget);
    });

    testWidgets('filter dialog allows entering species filter', (tester) async {
      final loadedState = MapLoaded(
        markers: const [],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Open filter dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Enter species filter
      await tester.enterText(
        find.widgetWithText(TextField, 'Species'),
        'Robin',
      );
      await tester.pump();

      // Verify text was entered
      expect(find.text('Robin'), findsOneWidget);
    });

    testWidgets('filter dialog allows entering location filter', (tester) async {
      final loadedState = MapLoaded(
        markers: const [],
        center: const MapPosition(latitude: 37.7749, longitude: -122.4194),
        clusteringEnabled: true,
      );

      when(mockMapBloc.state).thenReturn(loadedState);
      when(mockMapBloc.stream).thenAnswer((_) => Stream.value(loadedState));

      await tester.pumpWidget(createTestWidget(const MapScreen()));
      await tester.pump();

      // Open filter dialog
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Enter location filter
      await tester.enterText(
        find.widgetWithText(TextField, 'Location'),
        'San Francisco',
      );
      await tester.pump();

      // Verify text was entered
      expect(find.text('San Francisco'), findsOneWidget);
    });
  });
}
