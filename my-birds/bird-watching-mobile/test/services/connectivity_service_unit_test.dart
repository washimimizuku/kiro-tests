import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/data/services/connectivity_service.dart';

void main() {
  group('ConnectivityService Unit Tests', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    group('Service Interface', () {
      test('should have isConnected method', () {
        expect(connectivityService.isConnected, isA<Function>());
      });

      test('should have connectivityStream getter', () {
        expect(connectivityService.connectivityStream, isA<Stream>());
      });

      test('should be properly initialized', () {
        expect(connectivityService, isNotNull);
      });
    });

    group('Connectivity Monitoring', () {
      test('should provide connectivity stream', () {
        // Arrange & Act
        final stream = connectivityService.connectivityStream;

        // Assert
        expect(stream, isA<Stream>());
      });
    });
  });
}
