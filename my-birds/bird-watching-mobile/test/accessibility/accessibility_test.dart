import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/core/utils/accessibility_utils.dart';
import 'package:bird_watching_mobile/core/theme/accessible_theme.dart';

void main() {
  group('Accessibility Utils Tests', () {
    test('observationCardLabel generates correct label', () {
      final label = AccessibilityUtils.observationCardLabel(
        speciesName: 'American Robin',
        date: 'Jan 15, 2024',
        location: 'Central Park',
        hasPendingSync: true,
        hasPhoto: true,
      );

      expect(label, contains('American Robin'));
      expect(label, contains('Jan 15, 2024'));
      expect(label, contains('Central Park'));
      expect(label, contains('includes photo'));
      expect(label, contains('pending sync'));
    });

    test('tripCardLabel generates correct label', () {
      final label = AccessibilityUtils.tripCardLabel(
        tripName: 'Morning Walk',
        date: 'Jan 15, 2024',
        location: 'Central Park',
        observationCount: 5,
      );

      expect(label, contains('Morning Walk'));
      expect(label, contains('Jan 15, 2024'));
      expect(label, contains('Central Park'));
      expect(label, contains('5 observations'));
    });

    test('tripCardLabel handles singular observation', () {
      final label = AccessibilityUtils.tripCardLabel(
        tripName: 'Quick Trip',
        date: 'Jan 15, 2024',
        location: 'Park',
        observationCount: 1,
      );

      expect(label, contains('1 observation'));
      expect(label, isNot(contains('observations')));
    });

    test('photoButtonLabel generates correct labels', () {
      final takePhotoLabel = AccessibilityUtils.photoButtonLabel(
        hasPhoto: false,
        isCamera: true,
      );
      expect(takePhotoLabel, contains('Take photo'));

      final retakeLabel = AccessibilityUtils.photoButtonLabel(
        hasPhoto: true,
        isCamera: true,
      );
      expect(retakeLabel, contains('Retake'));

      final removeLabel = AccessibilityUtils.photoButtonLabel(
        hasPhoto: true,
        isCamera: false,
      );
      expect(removeLabel, contains('Remove'));
    });

    test('datePickerLabel formats date correctly', () {
      final date = DateTime(2024, 1, 15);
      final label = AccessibilityUtils.datePickerLabel(date);

      expect(label, contains('January 15, 2024'));
      expect(label, contains('tap to change'));
    });

    test('locationLabel includes coordinates when provided', () {
      final label = AccessibilityUtils.locationLabel(
        locationName: 'Central Park',
        latitude: 40.785091,
        longitude: -73.968285,
      );

      expect(label, contains('Central Park'));
      expect(label, contains('40.785091'));
      expect(label, contains('-73.968285'));
    });

    test('locationLabel works without coordinates', () {
      final label = AccessibilityUtils.locationLabel(
        locationName: 'Central Park',
      );

      expect(label, contains('Central Park'));
      expect(label, isNot(contains('coordinates')));
    });

    test('syncStatusLabel handles different states', () {
      final syncingLabel = AccessibilityUtils.syncStatusLabel(
        pendingCount: 3,
        isSyncing: true,
      );
      expect(syncingLabel, contains('Syncing'));
      expect(syncingLabel, contains('3'));

      final errorLabel = AccessibilityUtils.syncStatusLabel(
        pendingCount: 2,
        error: 'Network error',
      );
      expect(errorLabel, contains('Sync error'));
      expect(errorLabel, contains('Network error'));

      final pendingLabel = AccessibilityUtils.syncStatusLabel(
        pendingCount: 5,
      );
      expect(pendingLabel, contains('5 observations pending sync'));

      final completeLabel = AccessibilityUtils.syncStatusLabel(
        pendingCount: 0,
      );
      expect(completeLabel, contains('All observations synced'));
    });

    test('formFieldLabel includes all information', () {
      final label = AccessibilityUtils.formFieldLabel(
        fieldName: 'Species Name',
        isRequired: true,
        currentValue: 'Robin',
        error: 'Too short',
      );

      expect(label, contains('Species Name'));
      expect(label, contains('required'));
      expect(label, contains('Robin'));
      expect(label, contains('Too short'));
    });

    test('imageLabel generates descriptive text', () {
      final label = AccessibilityUtils.imageLabel(
        speciesName: 'Blue Jay',
        additionalInfo: 'thumbnail',
      );

      expect(label, contains('Photo of Blue Jay'));
      expect(label, contains('thumbnail'));
    });

    test('actionHint generates correct hint', () {
      final hint = AccessibilityUtils.actionHint('view details');
      expect(hint, contains('Double tap'));
      expect(hint, contains('view details'));
    });
  });

  group('Accessible Theme Tests', () {
    test('light theme with high contrast has proper colors', () {
      final theme = AccessibleTheme.createTheme(
        brightness: Brightness.light,
        highContrast: true,
      );

      // Check that high contrast colors are used
      expect(theme.colorScheme.onSurface, equals(const Color(0xFF000000)));
      expect(theme.colorScheme.surface, equals(const Color(0xFFFDFCFF)));
      
      // Check that borders are thicker
      expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
    });

    test('dark theme with high contrast has proper colors', () {
      final theme = AccessibleTheme.createTheme(
        brightness: Brightness.dark,
        highContrast: true,
      );

      // Check that high contrast colors are used
      expect(theme.colorScheme.background, equals(const Color(0xFF000000)));
      expect(theme.colorScheme.onBackground, equals(const Color(0xFFFFFFFF)));
    });

    test('normal theme has standard colors', () {
      final theme = AccessibleTheme.createTheme(
        brightness: Brightness.light,
        highContrast: false,
      );

      // Check that normal colors are used
      expect(theme.colorScheme.onSurface, isNot(equals(const Color(0xFF000000))));
    });

    test('theme has proper touch target sizes', () {
      final theme = AccessibleTheme.createTheme(
        brightness: Brightness.light,
        highContrast: false,
      );

      // Check minimum button sizes
      final elevatedButtonStyle = theme.elevatedButtonTheme.style;
      expect(elevatedButtonStyle?.minimumSize?.resolve({}), 
             equals(const Size(88, 48)));
    });

    test('high contrast theme has thicker borders', () {
      final normalTheme = AccessibleTheme.createTheme(
        brightness: Brightness.light,
        highContrast: false,
      );
      
      final highContrastTheme = AccessibleTheme.createTheme(
        brightness: Brightness.light,
        highContrast: true,
      );

      // High contrast should have thicker borders
      final normalBorder = normalTheme.inputDecorationTheme.border as OutlineInputBorder;
      final highContrastBorder = highContrastTheme.inputDecorationTheme.border as OutlineInputBorder;
      
      expect(highContrastBorder.borderSide.width, 
             greaterThan(normalBorder.borderSide.width));
    });
  });

  group('Widget Accessibility Tests', () {
    testWidgets('Semantics widget wraps buttons correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'Test button',
              button: true,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Click me'),
              ),
            ),
          ),
        ),
      );

      // Verify the Semantics widget exists
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Semantics widget wraps images correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'Photo of American Robin',
              image: true,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      // Verify the Semantics widget exists
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Semantics widget wraps text fields correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'Species Name, required',
              textField: true,
              child: const TextField(
                decoration: InputDecoration(
                  labelText: 'Species Name',
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the Semantics widget exists
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Semantics widget wraps switches correctly', (tester) async {
      bool value = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'Share with community, disabled',
              toggled: value,
              child: Switch(
                value: value,
                onChanged: (newValue) {
                  value = newValue;
                },
              ),
            ),
          ),
        ),
      );

      // Verify the Semantics widget exists
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byType(Switch), findsOneWidget);
    });
  });
}
