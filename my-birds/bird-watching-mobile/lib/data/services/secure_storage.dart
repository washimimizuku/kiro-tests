import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Service for securely storing sensitive data like authentication tokens
class SecureStorage {
  late final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage}) {
    _storage = storage ??
        const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );
  }

  /// Write a key-value pair to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print('[SecureStorage] Written key: $key');
    } catch (e) {
      print('[SecureStorage Error] Failed to write key $key: $e');
      rethrow;
    }
  }

  /// Read a value from secure storage
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      print('[SecureStorage] Read key: $key (${value != null ? 'found' : 'not found'})');
      return value;
    } catch (e) {
      print('[SecureStorage Error] Failed to read key $key: $e');
      rethrow;
    }
  }

  /// Delete a specific key from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      print('[SecureStorage] Deleted key: $key');
    } catch (e) {
      print('[SecureStorage Error] Failed to delete key $key: $e');
      rethrow;
    }
  }

  /// Delete all data from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      print('[SecureStorage] Deleted all keys');
    } catch (e) {
      print('[SecureStorage Error] Failed to delete all keys: $e');
      rethrow;
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      print('[SecureStorage Error] Failed to check key $key: $e');
      return false;
    }
  }

  /// Get all keys from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      final all = await _storage.readAll();
      print('[SecureStorage] Read all keys: ${all.keys.join(', ')}');
      return all;
    } catch (e) {
      print('[SecureStorage Error] Failed to read all keys: $e');
      rethrow;
    }
  }

  // Convenience methods for common operations

  /// Store authentication token
  Future<void> storeAuthToken(String token) async {
    await write(AppConstants.authTokenKey, token);
  }

  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    return await read(AppConstants.authTokenKey);
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    await delete(AppConstants.authTokenKey);
  }

  /// Store user ID
  Future<void> storeUserId(String userId) async {
    await write(AppConstants.userIdKey, userId);
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    return await read(AppConstants.userIdKey);
  }

  /// Store username
  Future<void> storeUsername(String username) async {
    await write(AppConstants.usernameKey, username);
  }

  /// Retrieve username
  Future<String?> getUsername() async {
    return await read(AppConstants.usernameKey);
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await delete(AppConstants.authTokenKey);
    await delete(AppConstants.userIdKey);
    await delete(AppConstants.usernameKey);
    print('[SecureStorage] Cleared all authentication data');
  }
}
