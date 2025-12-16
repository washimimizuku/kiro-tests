import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/data/services/gps_service.dart';

void main() {
  group('GpsService Unit Tests', () {
    late GpsService gpsService;

    setUp(() {
      gpsService = GpsService();
    });

    group('Service Interface', () {
      test('should have getCurrentPosition method', () {
        expect(gpsService.getCurrentPosition, isA<Function>());
      });

      test('should have isLocationServiceEnabled method', () {
        expect(gpsService.isLocationServiceEnabled, isA<Function>());
      });

      test('should have checkPermission method', () {
        expect(gpsService.checkPermission, isA<Function>());
      });

      test('should have requestPermission method', () {
        expect(gpsService.requestPermission, isA<Function>());
      });

      test('should be properly initialized', () {
        expect(gpsService, isNotNull);
      });
    });
  });
}
