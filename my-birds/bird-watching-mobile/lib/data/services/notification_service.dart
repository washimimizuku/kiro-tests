import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _notificationsEnabled = true;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with settings
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    _initialized = true;
    print('[NotificationService] Initialized');
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[NotificationService] Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Enable or disable notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    print('[NotificationService] Notifications ${enabled ? "enabled" : "disabled"}');
  }

  /// Check if notifications are enabled
  bool get notificationsEnabled => _notificationsEnabled;

  /// Show notification for successful sync
  Future<void> showSyncSuccessNotification(int syncedCount) async {
    if (!_notificationsEnabled || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0, // Notification ID
      'Sync Complete',
      '$syncedCount observation(s) synced successfully',
      details,
      payload: 'sync_success',
    );

    print('[NotificationService] Showed sync success notification');
  }

  /// Show notification for sync error
  Future<void> showSyncErrorNotification(String errorMessage, int failedCount) async {
    if (!_notificationsEnabled || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1, // Notification ID
      'Sync Failed',
      'Failed to sync $failedCount observation(s). Tap to retry.',
      details,
      payload: 'sync_error',
    );

    print('[NotificationService] Showed sync error notification');
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('[NotificationService] Cancelled all notifications');
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    print('[NotificationService] Cancelled notification $id');
  }
}
