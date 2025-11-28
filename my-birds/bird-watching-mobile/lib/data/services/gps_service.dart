import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';

/// Service for GPS location tracking
class GpsService {
  /// Get current GPS position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[GpsService] Location services are disabled');
        return null;
      }

      // Check and request permission
      final permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await requestPermission();
        if (requestedPermission == LocationPermission.denied ||
            requestedPermission == LocationPermission.deniedForever) {
          print('[GpsService] Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('[GpsService] Location permission permanently denied');
        return null;
      }

      // Get current position
      print('[GpsService] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: AppConstants.gpsTimeout,
      );

      print('[GpsService] Position obtained: '
          'lat=${position.latitude}, lon=${position.longitude}, '
          'accuracy=${position.accuracy}m');

      return position;
    } catch (e) {
      print('[GpsService Error] Failed to get current position: $e');
      return null;
    }
  }

  /// Get current position with custom accuracy
  Future<Position?> getCurrentPositionWithAccuracy(
    LocationAccuracy accuracy,
  ) async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[GpsService] Location services are disabled');
        return null;
      }

      final permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        final requestedPermission = await requestPermission();
        if (requestedPermission == LocationPermission.denied ||
            requestedPermission == LocationPermission.deniedForever) {
          print('[GpsService] Location permission denied');
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: AppConstants.gpsTimeout,
      );

      print('[GpsService] Position obtained with $accuracy: '
          'lat=${position.latitude}, lon=${position.longitude}');

      return position;
    } catch (e) {
      print('[GpsService Error] Failed to get position: $e');
      return null;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      print('[GpsService] Location services enabled: $enabled');
      return enabled;
    } catch (e) {
      print('[GpsService Error] Failed to check location service: $e');
      return false;
    }
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      print('[GpsService] Location permission: $permission');
      return permission;
    } catch (e) {
      print('[GpsService Error] Failed to check permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    try {
      print('[GpsService] Requesting location permission...');
      final permission = await Geolocator.requestPermission();
      print('[GpsService] Location permission result: $permission');
      return permission;
    } catch (e) {
      print('[GpsService Error] Failed to request permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Get stream of position updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    print('[GpsService] Starting position stream '
        '(accuracy: $accuracy, distanceFilter: ${distanceFilter}m)');

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        timeLimit: AppConstants.gpsTimeout,
      ),
    );
  }

  /// Check if GPS accuracy is acceptable
  bool isAccuracyAcceptable(Position position) {
    final acceptable = position.accuracy <= AppConstants.gpsAccuracyThreshold;
    print('[GpsService] Accuracy ${position.accuracy}m is '
        '${acceptable ? 'acceptable' : 'poor'}');
    return acceptable;
  }

  /// Get last known position (may be cached)
  Future<Position?> getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        print('[GpsService] Last known position: '
            'lat=${position.latitude}, lon=${position.longitude}');
      } else {
        print('[GpsService] No last known position available');
      }
      return position;
    } catch (e) {
      print('[GpsService Error] Failed to get last known position: $e');
      return null;
    }
  }

  /// Calculate distance between two positions in meters
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distance = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    print('[GpsService] Distance calculated: ${distance}m');
    return distance;
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      print('[GpsService] Opening location settings...');
      final opened = await Geolocator.openLocationSettings();
      print('[GpsService] Location settings opened: $opened');
      return opened;
    } catch (e) {
      print('[GpsService Error] Failed to open location settings: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      print('[GpsService] Opening app settings...');
      final opened = await Geolocator.openAppSettings();
      print('[GpsService] App settings opened: $opened');
      return opened;
    } catch (e) {
      print('[GpsService Error] Failed to open app settings: $e');
      return false;
    }
  }
}
