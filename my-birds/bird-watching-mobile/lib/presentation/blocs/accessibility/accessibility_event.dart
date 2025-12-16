import 'package:equatable/equatable.dart';

/// Events for accessibility settings
abstract class AccessibilityEvent extends Equatable {
  const AccessibilityEvent();

  @override
  List<Object?> get props => [];
}

/// Load accessibility settings from system
class LoadAccessibilitySettings extends AccessibilityEvent {
  const LoadAccessibilitySettings();
}

/// Update high contrast mode
class ToggleHighContrast extends AccessibilityEvent {
  final bool enabled;

  const ToggleHighContrast(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Update text scale factor
class UpdateTextScale extends AccessibilityEvent {
  final double scaleFactor;

  const UpdateTextScale(this.scaleFactor);

  @override
  List<Object?> get props => [scaleFactor];
}

/// Update reduce animations setting
class ToggleReduceAnimations extends AccessibilityEvent {
  final bool enabled;

  const ToggleReduceAnimations(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
