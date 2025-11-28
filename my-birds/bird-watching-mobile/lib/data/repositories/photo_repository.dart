import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/cache_manager_service.dart';
import '../../core/constants/app_constants.dart';

/// Repository for photo operations
/// Handles photo compression, upload, caching, and cache management
class PhotoRepository {
  final ApiService _apiService;

  PhotoRepository({
    required ApiService apiService,
  }) : _apiService = apiService;

  /// Upload a photo to the backend
  /// Returns the URL of the uploaded photo
  Future<String> uploadPhoto(File photo) async {
    try {
      print('[PhotoRepository] Uploading photo: ${photo.path}');
      
      final response = await _apiService.uploadFile(
        AppConstants.uploadEndpoint,
        photo,
        fieldName: 'photo',
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('[PhotoRepository] Upload progress: $progress%');
        },
      );

      final photoUrl = response.data['url'] as String;
      print('[PhotoRepository] Photo uploaded successfully: $photoUrl');
      
      return photoUrl;
    } on DioException catch (e) {
      print('[PhotoRepository Error] Failed to upload photo: ${e.message}');
      throw Exception('Failed to upload photo: ${e.message}');
    } catch (e) {
      print('[PhotoRepository Error] Unexpected error uploading photo: $e');
      rethrow;
    }
  }

  /// Compress a photo to reduce file size
  /// Returns the compressed photo file
  Future<File> compressPhoto(
    File photo, {
    int quality = AppConstants.imageQuality,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      print('[PhotoRepository] Compressing photo: ${photo.path}');
      
      final originalSize = await photo.length();
      print('[PhotoRepository] Original size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

      // Generate output path
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress the image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        photo.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth ?? AppConstants.maxImageWidth,
        minHeight: maxHeight ?? AppConstants.maxImageHeight,
      );

      if (compressedFile == null) {
        throw Exception('Failed to compress photo');
      }

      final compressedSize = await File(compressedFile.path).length();
      final reduction = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(1);
      
      print('[PhotoRepository] Compressed size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      print('[PhotoRepository] Size reduction: $reduction%');

      return File(compressedFile.path);
    } catch (e) {
      print('[PhotoRepository Error] Failed to compress photo: $e');
      rethrow;
    }
  }

  /// Cache a photo locally
  Future<void> cachePhoto(String url, File photo) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileNameFromUrl(url);
      final cachedFile = File(path.join(cacheDir.path, fileName));

      await photo.copy(cachedFile.path);
      
      print('[PhotoRepository] Cached photo: $fileName');
    } catch (e) {
      print('[PhotoRepository Error] Failed to cache photo: $e');
      rethrow;
    }
  }

  /// Get a cached photo
  /// Returns null if photo is not cached
  Future<File?> getCachedPhoto(String url) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileNameFromUrl(url);
      final cachedFile = File(path.join(cacheDir.path, fileName));

      if (await cachedFile.exists()) {
        print('[PhotoRepository] Found cached photo: $fileName');
        return cachedFile;
      }

      print('[PhotoRepository] Photo not in cache: $fileName');
      return null;
    } catch (e) {
      print('[PhotoRepository Error] Failed to get cached photo: $e');
      return null;
    }
  }

  /// Clear all cached photos
  Future<void> clearPhotoCache() async {
    try {
      // Clear both custom cache directory and flutter_cache_manager cache
      final cacheDir = await _getCacheDirectory();
      
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        print('[PhotoRepository] Cleared ${files.length} cached photos from custom cache');
      }

      // Clear flutter_cache_manager cache
      await PhotoCacheManager.clearCache();
      print('[PhotoRepository] Cleared flutter_cache_manager cache');
    } catch (e) {
      print('[PhotoRepository Error] Failed to clear photo cache: $e');
      rethrow;
    }
  }

  /// Get the total size of cached photos in bytes
  Future<int> getCacheSize() async {
    try {
      int totalSize = 0;

      // Get custom cache directory size
      final cacheDir = await _getCacheDirectory();
      
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync();
        
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      // Get flutter_cache_manager cache size
      final managerCacheSize = await PhotoCacheManager.getCacheSize();
      totalSize += managerCacheSize;

      print('[PhotoRepository] Total cache size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      return totalSize;
    } catch (e) {
      print('[PhotoRepository Error] Failed to get cache size: $e');
      return 0;
    }
  }

  /// Get the photo cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'photo_cache'));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  /// Extract filename from URL
  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    return path.basename(uri.path);
  }

  /// Download and cache a photo from URL
  Future<File?> downloadAndCachePhoto(String url) async {
    try {
      // Check if already cached
      final cached = await getCachedPhoto(url);
      if (cached != null) {
        return cached;
      }

      print('[PhotoRepository] Downloading photo: $url');

      // Download the photo
      final response = await _apiService.get(url);
      
      // Save to cache
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileNameFromUrl(url);
      final cachedFile = File(path.join(cacheDir.path, fileName));
      
      await cachedFile.writeAsBytes(response.data);
      
      print('[PhotoRepository] Downloaded and cached photo: $fileName');
      return cachedFile;
    } catch (e) {
      print('[PhotoRepository Error] Failed to download photo: $e');
      return null;
    }
  }

  /// Check if cache size exceeds threshold and clean if necessary
  Future<void> manageCacheSize() async {
    try {
      final cacheSize = await getCacheSize();
      
      if (cacheSize > AppConstants.maxCacheSize) {
        print('[PhotoRepository] Cache size exceeds threshold, cleaning...');
        
        final cacheDir = await _getCacheDirectory();
        final files = cacheDir.listSync();
        
        // Sort files by last modified date (oldest first)
        files.sort((a, b) {
          final aModified = (a as File).lastModifiedSync();
          final bModified = (b as File).lastModifiedSync();
          return aModified.compareTo(bModified);
        });

        // Delete oldest files until cache is under threshold
        int currentSize = cacheSize;
        for (final file in files) {
          if (currentSize <= AppConstants.maxCacheSize * 0.8) {
            break; // Keep cache at 80% of max
          }
          
          if (file is File) {
            final fileSize = await file.length();
            await file.delete();
            currentSize -= fileSize;
            print('[PhotoRepository] Deleted cached file: ${path.basename(file.path)}');
          }
        }
        
        print('[PhotoRepository] Cache cleaned. New size: ${(currentSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }
    } catch (e) {
      print('[PhotoRepository Error] Failed to manage cache size: $e');
    }
  }
}
