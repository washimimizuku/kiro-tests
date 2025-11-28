/// Form validation utilities for the Bird Watching Mobile App
/// 
/// Provides field-specific validators for forms throughout the app.
/// All validators return null if valid, or an error message string if invalid.

class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validates that a field is not empty
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates username format (alphanumeric, underscore, hyphen, 3-20 chars)
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    
    if (value.length > 20) {
      return 'Username must not exceed 20 characters';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }
    
    return null;
  }

  /// Validates password strength (minimum 8 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }

  /// Validates password confirmation matches
  static String? passwordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates latitude coordinates (-90 to 90)
  static String? latitude(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Latitude is optional
    }
    
    final lat = double.tryParse(value);
    if (lat == null) {
      return 'Latitude must be a valid number';
    }
    
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }
    
    return null;
  }

  /// Validates longitude coordinates (-180 to 180)
  static String? longitude(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Longitude is optional
    }
    
    final lon = double.tryParse(value);
    if (lon == null) {
      return 'Longitude must be a valid number';
    }
    
    if (lon < -180 || lon > 180) {
      return 'Longitude must be between -180 and 180';
    }
    
    return null;
  }

  /// Validates that a date is not in the future
  static String? notFutureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    // Compare dates only (ignore time)
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);
    
    if (selectedDate.isAfter(today)) {
      return 'Date cannot be in the future';
    }
    
    return null;
  }

  /// Validates text length does not exceed maximum
  static String? maxLength(String? value, int maxLength, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return null; // Empty is valid for optional fields
    }
    
    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    
    return null;
  }

  /// Validates text length meets minimum requirement
  static String? minLength(String? value, int minLength, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return null; // Empty is valid for optional fields
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validates species name (required, 2-100 characters)
  static String? speciesName(String? value) {
    final requiredError = required(value, fieldName: 'Species name');
    if (requiredError != null) return requiredError;
    
    final minError = minLength(value, 2, fieldName: 'Species name');
    if (minError != null) return minError;
    
    final maxError = maxLength(value, 100, fieldName: 'Species name');
    if (maxError != null) return maxError;
    
    return null;
  }

  /// Validates location name (required, 2-200 characters)
  static String? locationName(String? value) {
    final requiredError = required(value, fieldName: 'Location');
    if (requiredError != null) return requiredError;
    
    final minError = minLength(value, 2, fieldName: 'Location');
    if (minError != null) return minError;
    
    final maxError = maxLength(value, 200, fieldName: 'Location');
    if (maxError != null) return maxError;
    
    return null;
  }

  /// Validates notes (optional, max 1000 characters)
  static String? notes(String? value) {
    return maxLength(value, 1000, fieldName: 'Notes');
  }

  /// Validates trip name (required, 2-100 characters)
  static String? tripName(String? value) {
    final requiredError = required(value, fieldName: 'Trip name');
    if (requiredError != null) return requiredError;
    
    final minError = minLength(value, 2, fieldName: 'Trip name');
    if (minError != null) return minError;
    
    final maxError = maxLength(value, 100, fieldName: 'Trip name');
    if (maxError != null) return maxError;
    
    return null;
  }

  /// Validates trip description (optional, max 500 characters)
  static String? tripDescription(String? value) {
    return maxLength(value, 500, fieldName: 'Description');
  }

  /// Combines multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
