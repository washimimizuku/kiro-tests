import 'package:flutter/material.dart';

/// Utility class for accessibility helpers
class AccessibilityUtils {
  /// Generate semantic label for observation card
  static String observationCardLabel({
    required String speciesName,
    required String date,
    required String location,
    bool hasPendingSync = false,
    bool hasPhoto = false,
  }) {
    final buffer = StringBuffer();
    buffer.write('Observation: $speciesName, ');
    buffer.write('observed on $date, ');
    buffer.write('at $location');
    
    if (hasPhoto) {
      buffer.write(', includes photo');
    }
    
    if (hasPendingSync) {
      buffer.write(', pending sync');
    }
    
    return buffer.toString();
  }

  /// Generate semantic label for trip card
  static String tripCardLabel({
    required String tripName,
    required String date,
    required String location,
    required int observationCount,
  }) {
    return 'Trip: $tripName, on $date, at $location, '
        '$observationCount observation${observationCount == 1 ? '' : 's'}';
  }

  /// Generate semantic label for photo button
  static String photoButtonLabel({
    required bool hasPhoto,
    required bool isCamera,
  }) {
    if (hasPhoto) {
      return isCamera ? 'Retake photo with camera' : 'Remove photo';
    }
    return isCamera ? 'Take photo with camera' : 'Choose photo from gallery';
  }

  /// Generate semantic label for date picker
  static String datePickerLabel(DateTime date) {
    return 'Observation date: ${_formatDate(date)}, tap to change';
  }

  /// Generate semantic label for location with coordinates
  static String locationLabel({
    required String locationName,
    double? latitude,
    double? longitude,
  }) {
    final buffer = StringBuffer();
    buffer.write('Location: $locationName');
    
    if (latitude != null && longitude != null) {
      buffer.write(', coordinates: ${latitude.toStringAsFixed(6)}, '
          '${longitude.toStringAsFixed(6)}');
    }
    
    return buffer.toString();
  }

  /// Generate semantic label for sync status
  static String syncStatusLabel({
    required int pendingCount,
    bool isSyncing = false,
    String? error,
  }) {
    if (error != null) {
      return 'Sync error: $error';
    }
    
    if (isSyncing) {
      return 'Syncing $pendingCount observation${pendingCount == 1 ? '' : 's'}';
    }
    
    if (pendingCount > 0) {
      return '$pendingCount observation${pendingCount == 1 ? '' : 's'} pending sync';
    }
    
    return 'All observations synced';
  }

  /// Generate semantic label for map marker
  static String mapMarkerLabel({
    required String speciesName,
    required String location,
  }) {
    return 'Map marker: $speciesName at $location';
  }

  /// Generate semantic label for filter chip
  static String filterChipLabel({
    required String filterName,
    required bool isActive,
    String? value,
  }) {
    final buffer = StringBuffer();
    buffer.write('Filter: $filterName');
    
    if (isActive && value != null) {
      buffer.write(', active with value $value');
    } else if (isActive) {
      buffer.write(', active');
    } else {
      buffer.write(', inactive');
    }
    
    return buffer.toString();
  }

  /// Generate semantic label for form field
  static String formFieldLabel({
    required String fieldName,
    required bool isRequired,
    String? currentValue,
    String? error,
  }) {
    final buffer = StringBuffer();
    buffer.write(fieldName);
    
    if (isRequired) {
      buffer.write(', required');
    }
    
    if (currentValue != null && currentValue.isNotEmpty) {
      buffer.write(', current value: $currentValue');
    }
    
    if (error != null) {
      buffer.write(', error: $error');
    }
    
    return buffer.toString();
  }

  /// Generate semantic label for image
  static String imageLabel({
    required String speciesName,
    String? additionalInfo,
  }) {
    final buffer = StringBuffer();
    buffer.write('Photo of $speciesName');
    
    if (additionalInfo != null) {
      buffer.write(', $additionalInfo');
    }
    
    return buffer.toString();
  }

  /// Generate semantic hint for action
  static String actionHint(String action) {
    return 'Double tap to $action';
  }

  /// Format date for accessibility
  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Check if high contrast mode should be used
  static bool shouldUseHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get accessible text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Check if screen reader is enabled
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Announce message to screen reader
  static void announce(BuildContext context, String message) {
    if (isScreenReaderEnabled(context)) {
      // Use SemanticsService to announce
      // Note: This requires importing dart:ui
      // For now, we'll use a simple approach
      // In production, you would use: SemanticsService.announce(message, TextDirection.ltr);
    }
  }
}
