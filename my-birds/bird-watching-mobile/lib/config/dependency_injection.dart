import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import '../data/services/services.dart';
import '../data/repositories/repositories.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/observation/observation_bloc.dart';
import '../presentation/blocs/trip/trip_bloc.dart';
import '../presentation/blocs/sync/sync_bloc.dart';
import '../presentation/blocs/map/map_bloc.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Initialize all dependencies
/// This should be called in main() before runApp()
Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<Connectivity>(
    () => Connectivity(),
  );

  // Dio HTTP client
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );

    return dio;
  });

  // Services
  getIt.registerLazySingleton<SecureStorage>(
    () => SecureStorage(storage: getIt<FlutterSecureStorage>()),
  );

  getIt.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(),
  );

  getIt.registerLazySingleton<ApiService>(
    () => ApiService(dio: getIt<Dio>()),
  );

  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(connectivity: getIt<Connectivity>()),
  );

  getIt.registerLazySingleton<GpsService>(
    () => GpsService(),
  );

  getIt.registerLazySingleton<CameraService>(
    () => CameraService(),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      apiService: getIt<ApiService>(),
      secureStorage: getIt<SecureStorage>(),
    ),
  );

  getIt.registerLazySingleton<ObservationRepository>(
    () => ObservationRepository(
      apiService: getIt<ApiService>(),
      localDb: getIt<LocalDatabase>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<TripRepository>(
    () => TripRepository(
      apiService: getIt<ApiService>(),
      localDb: getIt<LocalDatabase>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerLazySingleton<PhotoRepository>(
    () => PhotoRepository(
      apiService: getIt<ApiService>(),
    ),
  );

  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      observationRepository: getIt<ObservationRepository>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // BLoCs - registered as factories (new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<ObservationBloc>(
    () => ObservationBloc(
      observationRepository: getIt<ObservationRepository>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  getIt.registerFactory<TripBloc>(
    () => TripBloc(
      tripRepository: getIt<TripRepository>(),
    ),
  );

  getIt.registerFactory<SyncBloc>(
    () => SyncBloc(
      syncService: getIt<SyncService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  getIt.registerFactory<MapBloc>(
    () => MapBloc(
      observationRepository: getIt<ObservationRepository>(),
      gpsService: getIt<GpsService>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
