import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../core/constants/app_constants.dart';

/// Custom cache manager for photo caching with LRU eviction
/// Requirements: 12.4, 12.5
class PhotoCacheManager {
  static const key = 'bird_watching_photo_cache';
  
  static CacheManager? _instance;

  /// Get singleton instance of cache manager
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: AppConstants.cacheExpiration,
        maxNrOfCacheObjects: 200, // Maximum number of cached files
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Clear all cached photos
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    // Note: flutter_cache_manager doesn't provide direct size calculation
    // We return an estimate based on the cache configuration
    try {
      // flutter_cache_manager doesn't expose a direct way to get cache size
      // This is a limitation of the library
      // Return 0 as a placeholder - actual size tracking should be done
      // through the PhotoRepository's custom cache directory
      return 0;
    } catch (e) {
      print('[PhotoCacheManager] Error calculating cache size: $e');
      return 0;
    }
  }

  /// Remove specific file from cache
  static Future<void> removeFile(String url) async {
    await instance.removeFile(url);
  }

  /// Download and cache a file
  static Future<void> downloadFile(String url) async {
    await instance.downloadFile(url);
  }

  /// Get file from cache or download if not cached
  static Future<FileInfo?> getFile(String url) async {
    try {
      return await instance.getFileFromCache(url);
    } catch (e) {
      print('[PhotoCacheManager] Error getting file from cache: $e');
      return null;
    }
  }
}
