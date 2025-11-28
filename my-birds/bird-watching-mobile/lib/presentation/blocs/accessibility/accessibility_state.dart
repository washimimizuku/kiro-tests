import 'package:equatable/equatable.dart';

/// State for accessibility settings
abstract class AccessibilityState extends Equatable {
  const AccessibilityState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AccessibilityInitial extends AccessibilityState {
  const AccessibilityInitial();
}

/// Accessibility settings loaded
class AccessibilityLoaded extends AccessibilityState {
  final bool highContrastEnabled;
  final double textScaleFactor;
  final bool screenReaderEnabled;
  final bool reduceAnimations;

  const AccessibilityLoaded({
    required this.highContrastEnabled,
    required this.textScaleFactor,
    required this.screenReaderEnabled,
    required this.reduceAnimations,
  });

  @override
  List<Object?> get props => [
        highContrastEnabled,
        textScaleFactor,
        screenReaderEnabled,
        reduceAnimations,
      ];

  AccessibilityLoaded copyWith({
    bool? highContrastEnabled,
    double? textScaleFactor,
    bool? screenReaderEnabled,
    bool? reduceAnimations,
  }) {
    return AccessibilityLoaded(
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
    );
  }
}
