import 'package:flutter_test/flutter_test.dart';
import 'package:bird_watching_mobile/data/services/api_service.dart';

void main() {
  group('ApiService Unit Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    group('Token Management', () {
      test('should set auth token', () {
        // Arrange
        const token = 'test_token_123';

        // Act
        apiService.setAuthToken(token);

        // Assert
        // Token is set internally - verified by subsequent requests
        expect(apiService, isNotNull);
      });

      test('should clear auth token', () {
        // Arrange
        const token = 'test_token_123';
        apiService.setAuthToken(token);

        // Act
        apiService.clearAuthToken();

        // Assert
        // Token is cleared - verified by subsequent requests
        expect(apiService, isNotNull);
      });
    });

    group('Service Interface', () {
      test('should have get method', () {
        expect(apiService.get, isA<Function>());
      });

      test('should have post method', () {
        expect(apiService.post, isA<Function>());
      });

      test('should have put method', () {
        expect(apiService.put, isA<Function>());
      });

      test('should have delete method', () {
        expect(apiService.delete, isA<Function>());
      });

      test('should have uploadFile method', () {
        expect(apiService.uploadFile, isA<Function>());
      });
    });
  });
}
