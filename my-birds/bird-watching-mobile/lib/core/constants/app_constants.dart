/// Application-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8080/api';
  static const String apiVersion = 'v1';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String observationsEndpoint = '/observations';
  static const String tripsEndpoint = '/trips';
  static const String usersEndpoint = '/users';
  static const String uploadEndpoint = '/upload';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
  static const String rememberMeKey = 'remember_me';

  // Preferences Keys
  static const String mapTypeKey = 'map_type';
  static const String autoSyncKey = 'auto_sync';
  static const String notificationsEnabledKey = 'notifications_enabled';

  // Database
  static const String databaseName = 'bird_watching.db';
  static const int databaseVersion = 1;
  static const String observationsTable = 'observations';
  static const String tripsTable = 'trips';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Configuration
  static const int imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int thumbnailSize = 200;
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB

  // Cache Configuration
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheExpiration = Duration(days: 7);

  // Network Configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const Duration syncDebounce = Duration(seconds: 5);
  static const int maxSyncBatchSize = 10;

  // Search Configuration
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int minSearchLength = 2;

  // GPS Configuration
  static const double gpsAccuracyThreshold = 50.0; // meters
  static const Duration gpsTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 50;
  static const int maxSpeciesNameLength = 100;
  static const int maxLocationLength = 200;
  static const int maxNotesLength = 1000;
  static const int maxTripNameLength = 100;
  static const int maxTripDescriptionLength = 500;

  // Coordinate Validation
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  // Map Configuration
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 20.0;
  static const int clusterRadius = 100;

  // Notification Configuration
  static const String notificationChannelId = 'bird_watching_channel';
  static const String notificationChannelName = 'Bird Watching Notifications';
  static const String notificationChannelDescription = 'Notifications for sync status and updates';

  // App Information
  static const String appName = 'Bird Watching';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@birdwatching.com';
}
