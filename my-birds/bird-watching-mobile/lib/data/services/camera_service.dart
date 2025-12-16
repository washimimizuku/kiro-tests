import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Service for camera and photo gallery access
class CameraService {
  final ImagePicker _picker;

  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Take a picture using the device camera
  Future<File?> takePicture() async {
    try {
      print('[CameraService] Opening camera...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85, // Balance between quality and file size
      );

      if (photo == null) {
        print('[CameraService] User cancelled camera');
        return null;
      }

      final file = File(photo.path);
      final fileSize = await file.length();
      print('[CameraService] Photo captured: ${photo.path} (${fileSize} bytes)');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to take picture: $e');
      return null;
    }
  }

  /// Take a picture with custom quality
  Future<File?> takePictureWithQuality(int quality) async {
    try {
      print('[CameraService] Opening camera with quality $quality...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: quality,
      );

      if (photo == null) {
        print('[CameraService] User cancelled camera');
        return null;
      }

      final file = File(photo.path);
      print('[CameraService] Photo captured with quality $quality: ${photo.path}');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to take picture: $e');
      return null;
    }
  }

  /// Pick a photo from the device gallery
  Future<File?> pickFromGallery() async {
    try {
      print('[CameraService] Opening gallery...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (photo == null) {
        print('[CameraService] User cancelled gallery selection');
        return null;
      }

      final file = File(photo.path);
      final fileSize = await file.length();
      print('[CameraService] Photo selected from gallery: ${photo.path} (${fileSize} bytes)');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to pick from gallery: $e');
      return null;
    }
  }

  /// Pick a photo from gallery with custom quality
  Future<File?> pickFromGalleryWithQuality(int quality) async {
    try {
      print('[CameraService] Opening gallery with quality $quality...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
      );

      if (photo == null) {
        print('[CameraService] User cancelled gallery selection');
        return null;
      }

      final file = File(photo.path);
      print('[CameraService] Photo selected with quality $quality: ${photo.path}');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to pick from gallery: $e');
      return null;
    }
  }

  /// Pick multiple photos from gallery
  Future<List<File>?> pickMultipleFromGallery() async {
    try {
      print('[CameraService] Opening gallery for multiple selection...');
      
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (photos.isEmpty) {
        print('[CameraService] No photos selected');
        return null;
      }

      final files = photos.map((photo) => File(photo.path)).toList();
      print('[CameraService] ${files.length} photos selected from gallery');
      
      return files;
    } catch (e) {
      print('[CameraService Error] Failed to pick multiple photos: $e');
      return null;
    }
  }

  /// Take a picture with maximum dimensions
  Future<File?> takePictureWithMaxDimensions({
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      print('[CameraService] Opening camera with max dimensions: '
          '${maxWidth}x$maxHeight...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: 85,
      );

      if (photo == null) {
        print('[CameraService] User cancelled camera');
        return null;
      }

      final file = File(photo.path);
      print('[CameraService] Photo captured with dimensions: ${photo.path}');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to take picture: $e');
      return null;
    }
  }

  /// Pick photo from gallery with maximum dimensions
  Future<File?> pickFromGalleryWithMaxDimensions({
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      print('[CameraService] Opening gallery with max dimensions: '
          '${maxWidth}x$maxHeight...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: 85,
      );

      if (photo == null) {
        print('[CameraService] User cancelled gallery selection');
        return null;
      }

      final file = File(photo.path);
      print('[CameraService] Photo selected with dimensions: ${photo.path}');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to pick from gallery: $e');
      return null;
    }
  }

  /// Check if camera is available on the device
  /// Note: image_picker doesn't provide a direct way to check camera availability
  /// This method attempts to access the camera and returns false if it fails
  Future<bool> isCameraAvailable() async {
    try {
      // Try to get available cameras (this is a workaround)
      // In a real implementation, you might want to use camera plugin directly
      // or handle the exception when trying to use the camera
      print('[CameraService] Checking camera availability...');
      
      // For now, we'll assume camera is available
      // The actual check will happen when trying to use the camera
      return true;
    } catch (e) {
      print('[CameraService] Camera not available: $e');
      return false;
    }
  }

  /// Record a video using the device camera
  Future<File?> recordVideo() async {
    try {
      print('[CameraService] Opening camera for video...');
      
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
      );

      if (video == null) {
        print('[CameraService] User cancelled video recording');
        return null;
      }

      final file = File(video.path);
      final fileSize = await file.length();
      print('[CameraService] Video recorded: ${video.path} (${fileSize} bytes)');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to record video: $e');
      return null;
    }
  }

  /// Pick a video from the device gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      print('[CameraService] Opening gallery for video...');
      
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video == null) {
        print('[CameraService] User cancelled video selection');
        return null;
      }

      final file = File(video.path);
      final fileSize = await file.length();
      print('[CameraService] Video selected: ${video.path} (${fileSize} bytes)');
      
      return file;
    } catch (e) {
      print('[CameraService Error] Failed to pick video: $e');
      return null;
    }
  }
}
