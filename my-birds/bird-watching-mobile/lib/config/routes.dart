import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/trips/trips_screen.dart';
import '../presentation/screens/trips/trip_detail_screen.dart';
import '../presentation/screens/trips/trip_form_screen.dart';
import '../presentation/screens/photos/photo_view_screen.dart';
import '../data/models/trip.dart';
import '../data/models/observation.dart';

/// Application route names
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';

  // Main routes
  static const String home = '/home';
  static const String observations = '/observations';
  static const String observationDetail = '/observation-detail';
  static const String observationForm = '/observation-form';
  static const String map = '/map';
  static const String trips = '/trips';
  static const String tripDetail = '/trip-detail';
  static const String tripForm = '/trip-form';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Photo routes
  static const String photoView = '/photo-view';

  /// List of routes that require authentication
  static const List<String> _protectedRoutes = [
    home,
    observations,
    observationDetail,
    observationForm,
    map,
    trips,
    tripDetail,
    tripForm,
    community,
    profile,
    settings,
    photoView,
  ];

  /// Check if a route requires authentication
  static bool isProtectedRoute(String? routeName) {
    return routeName != null && _protectedRoutes.contains(routeName);
  }

  /// Generate routes for the application
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _buildRoute(const LoginScreen(), settings);

      case '/register':
        return _buildRoute(const RegisterScreen(), settings);

      case '/home':
        return _buildRoute(const HomeScreen(), settings);

      case '/observations':
        // return MaterialPageRoute(builder: (_) => ObservationsScreen());
        return _buildPlaceholderRoute('Observations Screen', settings);

      case '/observation-detail':
        // final args = settings.arguments as Map<String, dynamic>;
        // return MaterialPageRoute(
        //   builder: (_) => ObservationDetailScreen(observationId: args['id']),
        // );
        return _buildPlaceholderRoute('Observation Detail Screen', settings);

      case '/observation-form':
        // final args = settings.arguments as Map<String, dynamic>?;
        // return MaterialPageRoute(
        //   builder: (_) => ObservationFormScreen(observation: args?['observation']),
        // );
        return _buildPlaceholderRoute('Observation Form Screen', settings);

      case '/map':
        // return MaterialPageRoute(builder: (_) => MapScreen());
        return _buildPlaceholderRoute('Map Screen', settings);

      case '/trips':
        return _buildRoute(const TripsScreen(), settings);

      case '/trip-detail':
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          TripDetailScreen(tripId: args['id'] as String),
          settings,
        );

      case '/trip-form':
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          TripFormScreen(trip: args?['trip'] as Trip?),
          settings,
        );

      case '/community':
        // return MaterialPageRoute(builder: (_) => CommunityScreen());
        return _buildPlaceholderRoute('Community Screen', settings);

      case '/profile':
        // return MaterialPageRoute(builder: (_) => ProfileScreen());
        return _buildPlaceholderRoute('Profile Screen', settings);

      case '/settings':
        // return MaterialPageRoute(builder: (_) => SettingsScreen());
        return _buildPlaceholderRoute('Settings Screen', settings);

      case '/photo-view':
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(
          PhotoViewScreen(
            photoUrl: args['photoUrl'] as String?,
            localPhotoPath: args['localPhotoPath'] as String?,
            observation: args['observation'] as Observation?,
          ),
          settings,
        );

      default:
        return _buildErrorRoute(settings);
    }
  }

  /// Build a route with custom page transition
  static PageRoute _buildRoute(Widget screen, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition from right to left
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Build a placeholder route for screens not yet implemented
  static PageRoute _buildPlaceholderRoute(
    String screenName,
    RouteSettings settings,
  ) {
    return _buildRoute(
      Scaffold(
        appBar: AppBar(title: Text(screenName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                screenName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Coming soon...'),
              if (settings.arguments != null) ...[
                const SizedBox(height: 16),
                Text('Arguments: ${settings.arguments}'),
              ],
            ],
          ),
        ),
      ),
      settings,
    );
  }

  /// Build an error route for unknown routes
  static PageRoute _buildErrorRoute(RouteSettings settings) {
    return _buildRoute(
      Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Route not found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('No route defined for ${settings.name}'),
            ],
          ),
        ),
      ),
      settings,
    );
  }
}
