import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/dependency_injection.dart';
import 'config/routes.dart';
import 'core/constants/app_constants.dart';
import 'data/services/notification_service.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/observation/observation_bloc.dart';
import 'presentation/blocs/trip/trip_bloc.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/blocs/map/map_bloc.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await initializeDependencies();

  // Initialize notification service
  await getIt<NotificationService>().initialize();

  runApp(const BirdWatchingApp());
}

class BirdWatchingApp extends StatelessWidget {
  const BirdWatchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<ObservationBloc>(
          create: (context) => getIt<ObservationBloc>(),
        ),
        BlocProvider<TripBloc>(
          create: (context) => getIt<TripBloc>(),
        ),
        BlocProvider<SyncBloc>(
          create: (context) => getIt<SyncBloc>(),
        ),
        BlocProvider<MapBloc>(
          create: (context) => getIt<MapBloc>(),
        ),
      ],
      child: const BirdWatchingAppView(),
    );
  }
}

class BirdWatchingAppView extends StatelessWidget {
  const BirdWatchingAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Show loading while checking auth status
          if (state is AuthInitial || state is AuthLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Navigate to home if authenticated
          if (state is Authenticated) {
            return const _AuthenticatedNavigator();
          }

          // Show login screen if not authenticated
          return const _UnauthenticatedNavigator();
        },
      ),
    );
  }
}

/// Navigator for authenticated users
class _AuthenticatedNavigator extends StatelessWidget {
  const _AuthenticatedNavigator();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        // Default to home screen for authenticated users
        if (settings.name == null || settings.name == '/') {
          return AppRoutes.generateRoute(
            const RouteSettings(name: AppRoutes.home),
          );
        }
        return AppRoutes.generateRoute(settings);
      },
    );
  }
}

/// Navigator for unauthenticated users
class _UnauthenticatedNavigator extends StatelessWidget {
  const _UnauthenticatedNavigator();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        // Only allow auth routes for unauthenticated users
        if (settings.name == AppRoutes.register) {
          return AppRoutes.generateRoute(settings);
        }
        // Default to login screen
        return AppRoutes.generateRoute(
          const RouteSettings(name: AppRoutes.login),
        );
      },
    );
  }
}
