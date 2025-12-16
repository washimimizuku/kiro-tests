import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';

import 'package:bird_watching_mobile/presentation/screens/auth/login_screen.dart';
import 'package:bird_watching_mobile/presentation/screens/auth/register_screen.dart';
import 'package:bird_watching_mobile/presentation/blocs/auth/auth.dart';
import 'package:bird_watching_mobile/data/repositories/auth_repository.dart';

import 'auth_screens_widget_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  /// Helper to wrap widgets with necessary providers
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(authRepository: mockAuthRepository),
        child: child,
      ),
      routes: {
        '/home': (context) => const Scaffold(body: Text('Home Screen')),
        '/register': (context) => const Scaffold(body: Text('Register Screen')),
      },
    );
  }

  /// Helper to scroll to make widgets visible
  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login form with all required fields', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Verify all form fields are present
      expect(find.text('Bird Watching'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Username and password
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets('password visibility toggle works', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Initially visibility_off icon should be present
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      // Now visibility icon should be present
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      // Back to visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
    });

    testWidgets('remember me checkbox toggles', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Find checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Initially unchecked
      Checkbox checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, isFalse);

      // Tap checkbox
      await tester.tap(checkbox);
      await tester.pump();

      // Should be checked
      checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, isTrue);
    });

    testWidgets('validates empty username', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Tap sign in without entering username
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('validates short username', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Enter short username
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'ab',
      );

      // Tap sign in
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('validates empty password', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Enter valid username but no password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );

      // Tap sign in
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));

      // Enter valid username
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );

      // Enter short password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        '12345',
      );

      // Tap sign in
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });


  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders registration form with all required fields', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Verify all form fields are present
      expect(find.text('Join Bird Watching'), findsOneWidget);
      expect(find.text('Create your account to start'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Username, email, password, confirm
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('password visibility toggles work', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Initially visibility_off icons should be present (2 for password fields)
      expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(2));

      // Tap first visibility toggle (password)
      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      // Now at least one visibility icon should be present
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty username', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Scroll to make button visible
      await scrollToBottom(tester);

      // Tap create account without entering username
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'), warnIfMissed: false);
      await tester.pump();

      // Should show validation error
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('validates short username', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Enter short username
      final usernameField = find.widgetWithText(TextFormField, 'Username');
      await tester.enterText(usernameField, 'ab');

      // Scroll to make button visible
      await scrollToBottom(tester);

      // Tap create account
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'), warnIfMissed: false);
      await tester.pump();

      // Should show validation error
      expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('validates invalid username characters', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Enter username with invalid characters
      final usernameField = find.widgetWithText(TextFormField, 'Username');
      await tester.enterText(usernameField, 'test@user');

      // Scroll to make button visible
      await scrollToBottom(tester);

      // Tap create account
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'), warnIfMissed: false);
      await tester.pump();

      // Should show validation error
      expect(
        find.text('Username can only contain letters, numbers, and underscores'),
        findsOneWidget,
      );
    });

    testWidgets('validates invalid email format', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Enter valid username
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'notanemail',
      );

      // Scroll to make button visible
      await scrollToBottom(tester);

      // Tap create account
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'), warnIfMissed: false);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('validates password confirmation', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));

      // Enter valid username, email, and password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Enter different confirm password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm Password'),
        'password456',
      );

      // Scroll to make button visible
      await scrollToBottom(tester);

      // Tap create account
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'), warnIfMissed: false);
      await tester.pump();

      // Should show validation error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
