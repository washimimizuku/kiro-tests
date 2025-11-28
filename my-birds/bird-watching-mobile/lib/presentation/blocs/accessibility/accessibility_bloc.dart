import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'accessibility_event.dart';
import 'accessibility_state.dart';

/// BLoC for managing accessibility settings
class AccessibilityBloc extends Bloc<AccessibilityEvent, AccessibilityState> {
  final SharedPreferences _prefs;

  static const String _highContrastKey = 'high_contrast_enabled';
  static const String _textScaleKey = 'text_scale_factor';
  static const String _reduceAnimationsKey = 'reduce_animations';

  AccessibilityBloc(this._prefs) : super(const AccessibilityInitial()) {
    on<LoadAccessibilitySettings>(_onLoadSettings);
    on<ToggleHighContrast>(_onToggleHighContrast);
    on<UpdateTextScale>(_onUpdateTextScale);
    on<ToggleReduceAnimations>(_onToggleReduceAnimations);
  }

  Future<void> _onLoadSettings(
    LoadAccessibilitySettings event,
    Emitter<AccessibilityState> emit,
  ) async {
    final highContrast = _prefs.getBool(_highContrastKey) ?? false;
    final textScale = _prefs.getDouble(_textScaleKey) ?? 1.0;
    final reduceAnimations = _prefs.getBool(_reduceAnimationsKey) ?? false;

    emit(AccessibilityLoaded(
      highContrastEnabled: highContrast,
      textScaleFactor: textScale,
      screenReaderEnabled: false, // This is detected from system, not stored
      reduceAnimations: reduceAnimations,
    ));
  }

  Future<void> _onToggleHighContrast(
    ToggleHighContrast event,
    Emitter<AccessibilityState> emit,
  ) async {
    await _prefs.setBool(_highContrastKey, event.enabled);

    if (state is AccessibilityLoaded) {
      emit((state as AccessibilityLoaded).copyWith(
        highContrastEnabled: event.enabled,
      ));
    }
  }

  Future<void> _onUpdateTextScale(
    UpdateTextScale event,
    Emitter<AccessibilityState> emit,
  ) async {
    await _prefs.setDouble(_textScaleKey, event.scaleFactor);

    if (state is AccessibilityLoaded) {
      emit((state as AccessibilityLoaded).copyWith(
        textScaleFactor: event.scaleFactor,
      ));
    }
  }

  Future<void> _onToggleReduceAnimations(
    ToggleReduceAnimations event,
    Emitter<AccessibilityState> emit,
  ) async {
    await _prefs.setBool(_reduceAnimationsKey, event.enabled);

    if (state is AccessibilityLoaded) {
      emit((state as AccessibilityLoaded).copyWith(
        reduceAnimations: event.enabled,
      ));
    }
  }
}
