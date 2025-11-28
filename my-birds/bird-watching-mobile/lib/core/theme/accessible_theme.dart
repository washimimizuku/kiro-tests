import 'package:flutter/material.dart';

/// Theme configuration that supports accessibility features
class AccessibleTheme {
  /// Create a theme that respects accessibility settings
  static ThemeData createTheme({
    required Brightness brightness,
    required bool highContrast,
  }) {
    final baseColorScheme = brightness == Brightness.light
        ? _lightColorScheme(highContrast)
        : _darkColorScheme(highContrast);

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      
      // Typography that scales with system font size
      textTheme: _createTextTheme(baseColorScheme, highContrast),
      
      // Ensure sufficient contrast for interactive elements
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 48), // Larger touch targets
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            width: highContrast ? 2 : 1,
            color: baseColorScheme.primary,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input decoration with better contrast
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseColorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            width: highContrast ? 2 : 1,
            color: baseColorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            width: highContrast ? 2 : 1,
            color: baseColorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            width: highContrast ? 3 : 2,
            color: baseColorScheme.primary,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            width: highContrast ? 2 : 1,
            color: baseColorScheme.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Card theme with better contrast
      cardTheme: CardThemeData(
        elevation: highContrast ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(
                  color: baseColorScheme.outline,
                  width: 1,
                )
              : BorderSide.none,
        ),
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
        size: 24,
        color: baseColorScheme.onSurface,
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: highContrast ? 4 : 0,
        backgroundColor: baseColorScheme.surface,
        foregroundColor: baseColorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: baseColorScheme.onSurface,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: baseColorScheme.primary,
        unselectedItemColor: baseColorScheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        elevation: highContrast ? 8 : 3,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: highContrast ? 8 : 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: highContrast
              ? BorderSide(
                  color: baseColorScheme.outline,
                  width: 2,
                )
              : BorderSide.none,
        ),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        thickness: highContrast ? 2 : 1,
        color: baseColorScheme.outline,
      ),
    );
  }

  /// Create text theme with proper scaling
  static TextTheme _createTextTheme(
    ColorScheme colorScheme,
    bool highContrast,
  ) {
    final baseColor = colorScheme.onSurface;
    final fontWeight = highContrast ? FontWeight.w600 : FontWeight.normal;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: fontWeight,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: fontWeight,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: fontWeight,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: fontWeight,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: fontWeight,
        color: baseColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
    );
  }

  /// Light color scheme with optional high contrast
  static ColorScheme _lightColorScheme(bool highContrast) {
    if (highContrast) {
      return const ColorScheme.light(
        primary: Color(0xFF005AC1), // Darker blue for better contrast
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFD8E2FF),
        onPrimaryContainer: Color(0xFF001A41),
        secondary: Color(0xFF535F70),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFD7E3F7),
        onSecondaryContainer: Color(0xFF101C2B),
        tertiary: Color(0xFF6B5778),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFF2DAFF),
        onTertiaryContainer: Color(0xFF251431),
        error: Color(0xFFBA1A1A), // High contrast red
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        background: Color(0xFFFDFCFF),
        onBackground: Color(0xFF000000), // Pure black for maximum contrast
        surface: Color(0xFFFDFCFF),
        onSurface: Color(0xFF000000),
        surfaceVariant: Color(0xFFE1E2EC),
        onSurfaceVariant: Color(0xFF000000),
        outline: Color(0xFF000000), // Black outlines
        outlineVariant: Color(0xFF444746),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFF2F3033),
        onInverseSurface: Color(0xFFFFFFFF),
        inversePrimary: Color(0xFFADC6FF),
      );
    }
    
    return const ColorScheme.light(
      primary: Color(0xFF0061A4),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFD1E4FF),
      onPrimaryContainer: Color(0xFF001D36),
      secondary: Color(0xFF535F70),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFD7E3F7),
      onSecondaryContainer: Color(0xFF101C2B),
      tertiary: Color(0xFF6B5778),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFF2DAFF),
      onTertiaryContainer: Color(0xFF251431),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      background: Color(0xFFFDFCFF),
      onBackground: Color(0xFF1A1C1E),
      surface: Color(0xFFFDFCFF),
      onSurface: Color(0xFF1A1C1E),
      surfaceVariant: Color(0xFFDFE2EB),
      onSurfaceVariant: Color(0xFF43474E),
      outline: Color(0xFF73777F),
      outlineVariant: Color(0xFFC3C7CF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFF9ECAFF),
    );
  }

  /// Dark color scheme with optional high contrast
  static ColorScheme _darkColorScheme(bool highContrast) {
    if (highContrast) {
      return const ColorScheme.dark(
        primary: Color(0xFFD0E4FF), // Lighter blue for better contrast on dark
        onPrimary: Color(0xFF000000),
        primaryContainer: Color(0xFF004A77),
        onPrimaryContainer: Color(0xFFFFFFFF),
        secondary: Color(0xFFBBC7DB),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF3C4858),
        onSecondaryContainer: Color(0xFFFFFFFF),
        tertiary: Color(0xFFD6BEE4),
        onTertiary: Color(0xFF000000),
        tertiaryContainer: Color(0xFF533F5F),
        onTertiaryContainer: Color(0xFFFFFFFF),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF000000),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFFFFF),
        background: Color(0xFF000000), // Pure black
        onBackground: Color(0xFFFFFFFF), // Pure white
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
        surfaceVariant: Color(0xFF43474E),
        onSurfaceVariant: Color(0xFFFFFFFF),
        outline: Color(0xFFFFFFFF), // White outlines
        outlineVariant: Color(0xFFC3C7CF),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: Color(0xFFE2E2E6),
        onInverseSurface: Color(0xFF000000),
        inversePrimary: Color(0xFF0061A4),
      );
    }
    
    return const ColorScheme.dark(
      primary: Color(0xFF9ECAFF),
      onPrimary: Color(0xFF003258),
      primaryContainer: Color(0xFF00497D),
      onPrimaryContainer: Color(0xFFD1E4FF),
      secondary: Color(0xFFBBC7DB),
      onSecondary: Color(0xFF253140),
      secondaryContainer: Color(0xFF3C4858),
      onSecondaryContainer: Color(0xFFD7E3F7),
      tertiary: Color(0xFFD6BEE4),
      onTertiary: Color(0xFF3B2948),
      tertiaryContainer: Color(0xFF533F5F),
      onTertiaryContainer: Color(0xFFF2DAFF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      background: Color(0xFF1A1C1E),
      onBackground: Color(0xFFE2E2E6),
      surface: Color(0xFF1A1C1E),
      onSurface: Color(0xFFE2E2E6),
      surfaceVariant: Color(0xFF43474E),
      onSurfaceVariant: Color(0xFFC3C7CF),
      outline: Color(0xFF8D9199),
      outlineVariant: Color(0xFF43474E),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE2E2E6),
      onInverseSurface: Color(0xFF2F3033),
      inversePrimary: Color(0xFF0061A4),
    );
  }
}
