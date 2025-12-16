import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/accessibility/accessibility_bloc.dart';
import '../blocs/accessibility/accessibility_state.dart';
import '../../core/theme/accessible_theme.dart';

/// Wrapper widget that applies accessibility settings to the app
class AccessibleAppWrapper extends StatelessWidget {
  final Widget child;
  final Brightness brightness;

  const AccessibleAppWrapper({
    super.key,
    required this.child,
    this.brightness = Brightness.light,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccessibilityBloc, AccessibilityState>(
      builder: (context, state) {
        // Get system accessibility settings
        final mediaQuery = MediaQuery.of(context);
        final systemHighContrast = mediaQuery.highContrast;
        final systemTextScale = mediaQuery.textScaleFactor;
        final systemReduceAnimations = mediaQuery.disableAnimations;

        // Determine effective settings
        bool effectiveHighContrast = systemHighContrast;
        double effectiveTextScale = systemTextScale;
        bool effectiveReduceAnimations = systemReduceAnimations;

        if (state is AccessibilityLoaded) {
          // User preferences override system settings
          effectiveHighContrast = state.highContrastEnabled || systemHighContrast;
          effectiveTextScale = state.textScaleFactor * systemTextScale;
          effectiveReduceAnimations = state.reduceAnimations || systemReduceAnimations;
        }

        // Create theme based on accessibility settings
        final theme = AccessibleTheme.createTheme(
          brightness: brightness,
          highContrast: effectiveHighContrast,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: effectiveTextScale,
            disableAnimations: effectiveReduceAnimations,
          ),
          child: Theme(
            data: theme,
            child: child,
          ),
        );
      },
    );
  }
}
