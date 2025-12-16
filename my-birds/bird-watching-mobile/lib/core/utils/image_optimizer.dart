import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utility class for optimizing images
class ImageOptimizer {
  /// Target quality for image compression (0-100)
  static const int defaultQuality = 85;

  /// Maximum width for uploaded images
  static const int maxWidth = 1920;

  /// Maximum height for uploaded images
  static const int maxHeight = 1920;

  /// Thumbnail width for list views
  static const int thumbnailWidth = 400;

  /// Thumbnail height for list views
  static const int thumbnailHeight = 400;

  /// Compress an image file for upload
  /// Returns the compressed file or null if compression fails
  static Future<File?> compressForUpload(
    File file, {
    int quality = defaultQuality,
    int maxWidth = maxWidth,
    int maxHeight = maxHeight,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed${path.extension(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: _getCompressFormat(file.path),
      );

      if (result == null) {
        return null;
      }

      return File(result.path);
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Create a thumbnail for list views
  /// Returns the thumbnail file or null if creation fails
  static Future<File?> createThumbnail(
    File file, {
    int width = thumbnailWidth,
    int height = thumbnailHeight,
    int quality = defaultQuality,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_thumb${path.extension(file.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: width,
        minHeight: height,
        format: _getCompressFormat(file.path),
      );

      if (result == null) {
        return null;
      }

      return File(result.path);
    } catch (e) {
      print('Error creating thumbnail: $e');
      return null;
    }
  }

  /// Compress image to bytes for in-memory operations
  static Future<Uint8List?> compressToBytes(
    File file, {
    int quality = defaultQuality,
    int maxWidth = maxWidth,
    int maxHeight = maxHeight,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: _getCompressFormat(file.path),
      );

      return result;
    } catch (e) {
      print('Error compressing image to bytes: $e');
      return null;
    }
  }

  /// Get the appropriate compression format based on file extension
  static CompressFormat _getCompressFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.png':
        return CompressFormat.png;
      case '.webp':
        return CompressFormat.webp;
      case '.heic':
        return CompressFormat.heic;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// Calculate compression ratio
  static Future<double> getCompressionRatio(File original, File compressed) async {
    try {
      final originalSize = await original.length();
      final compressedSize = await compressed.length();
      
      if (originalSize == 0) return 0.0;
      
      return (originalSize - compressedSize) / originalSize;
    } catch (e) {
      print('Error calculating compression ratio: $e');
      return 0.0;
    }
  }

  /// Get human-readable file size
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if image needs compression
  static Future<bool> needsCompression(
    File file, {
    int maxSizeBytes = 1024 * 1024, // 1MB default
  }) async {
    try {
      final size = await file.length();
      return size > maxSizeBytes;
    } catch (e) {
      print('Error checking file size: $e');
      return false;
    }
  }
}
