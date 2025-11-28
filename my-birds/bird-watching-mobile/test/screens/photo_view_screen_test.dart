import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/presentation/screens/photos/photo_view_screen.dart';
import 'package:bird_watching_mobile/data/models/observation.dart';

void main() {
  group('PhotoViewScreen Widget Tests', () {
    testWidgets('PhotoViewScreen displays with network photo URL',
        (WidgetTester tester) async {
      // Create a test observation
      final observation = Observation(
        id: 'test-id',
        userId: 'user-1',
        speciesName: 'Blue Jay',
        observationDate: DateTime(2024, 1, 15),
        location: 'Central Park',
        latitude: 40.7829,
        longitude: -73.9654,
        photoUrl: 'https://example.com/photo.jpg',
        isShared: true,
        createdAt: DateTime(2024, 1, 15),
        updatedAt: DateTime(2024, 1, 15),
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: PhotoViewScreen(
            photoUrl: observation.photoUrl,
            observation: observation,
          ),
        ),
      );

      // Verify the screen is displayed
      expect(find.byType(PhotoViewScreen), findsOneWidget);
      
      // Verify app bar is shown (overlay is visible by default)
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify close button exists
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      // Verify share button exists
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('PhotoViewScreen displays observation details overlay',
        (WidgetTester tester) async {
      final observation = Observation(
        id: 'test-id',
        userId: 'user-1',
        speciesName: 'Cardinal',
        observationDate: DateTime(2024, 2, 20),
        location: 'Backyard',
        notes: 'Beautiful red bird',
        photoUrl: 'https://example.com/cardinal.jpg',
        isShared: false,
        createdAt: DateTime(2024, 2, 20),
        updatedAt: DateTime(2024, 2, 20),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PhotoViewScreen(
            photoUrl: observation.photoUrl,
            observation: observation,
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify observation details are displayed
      expect(find.text('Cardinal'), findsOneWidget);
      expect(find.text('Backyard'), findsOneWidget);
      expect(find.text('Beautiful red bird'), findsOneWidget);
    });

    testWidgets('PhotoViewScreen works with local photo path',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PhotoViewScreen(
            localPhotoPath: '/path/to/local/photo.jpg',
          ),
        ),
      );

      // Verify the screen is displayed
      expect(find.byType(PhotoViewScreen), findsOneWidget);
      
      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('PhotoViewScreen displays without observation details',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PhotoViewScreen(
            photoUrl: 'https://example.com/photo.jpg',
          ),
        ),
      );

      // Verify the screen is displayed
      expect(find.byType(PhotoViewScreen), findsOneWidget);
      
      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
      
      // No observation details should be shown
      await tester.pump();
      // The overlay container should not have observation details
    });

    testWidgets('PhotoViewScreen close button navigates back',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhotoViewScreen(
                        photoUrl: 'https://example.com/photo.jpg',
                      ),
                    ),
                  );
                },
                child: const Text('Open Photo'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to navigate to PhotoViewScreen
      await tester.tap(find.text('Open Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we're on the PhotoViewScreen
      expect(find.byType(PhotoViewScreen), findsOneWidget);

      // Tap the close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we navigated back
      expect(find.byType(PhotoViewScreen), findsNothing);
      expect(find.text('Open Photo'), findsOneWidget);
    });
  });
}
