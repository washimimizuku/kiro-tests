import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/accessibility/accessibility_bloc.dart';
import '../../blocs/accessibility/accessibility_state.dart';
import '../../blocs/accessibility/accessibility_event.dart';
import '../../../core/utils/accessibility_utils.dart';

/// Screen for managing accessibility settings
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
      ),
      body: BlocBuilder<AccessibilityBloc, AccessibilityState>(
        builder: (context, state) {
          if (state is! AccessibilityLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // High Contrast Mode
              Semantics(
                label: 'High contrast mode, ${state.highContrastEnabled ? 'enabled' : 'disabled'}',
                hint: 'Double tap to ${state.highContrastEnabled ? 'disable' : 'enable'}',
                toggled: state.highContrastEnabled,
                child: SwitchListTile(
                  title: const Text('High Contrast Mode'),
                  subtitle: const Text(
                    'Increases contrast for better visibility',
                  ),
                  value: state.highContrastEnabled,
                  onChanged: (value) {
                    context.read<AccessibilityBloc>().add(
                          ToggleHighContrast(value),
                        );
                    
                    // Announce change to screen reader
                    AccessibilityUtils.announce(
                      context,
                      'High contrast mode ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                  secondary: const Icon(Icons.contrast),
                ),
              ),
              const Divider(),

              // Text Size
              Semantics(
                label: 'Text size: ${_getTextSizeLabel(state.textScaleFactor)}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.text_fields),
                      title: const Text('Text Size'),
                      subtitle: Text(
                        _getTextSizeLabel(state.textScaleFactor),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Semantics(
                            label: 'Text size slider, current value ${state.textScaleFactor.toStringAsFixed(1)}',
                            slider: true,
                            child: Slider(
                              value: state.textScaleFactor,
                              min: 0.8,
                              max: 2.0,
                              divisions: 12,
                              label: state.textScaleFactor.toStringAsFixed(1),
                              onChanged: (value) {
                                context.read<AccessibilityBloc>().add(
                                      UpdateTextScale(value),
                                    );
                              },
                              onChangeEnd: (value) {
                                // Announce final value to screen reader
                                AccessibilityUtils.announce(
                                  context,
                                  'Text size set to ${_getTextSizeLabel(value)}',
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Small',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Large',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Preview text
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preview',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is how text will appear in the app',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Reduce Animations
              Semantics(
                label: 'Reduce animations, ${state.reduceAnimations ? 'enabled' : 'disabled'}',
                hint: 'Double tap to ${state.reduceAnimations ? 'disable' : 'enable'}',
                toggled: state.reduceAnimations,
                child: SwitchListTile(
                  title: const Text('Reduce Animations'),
                  subtitle: const Text(
                    'Minimizes motion and animations',
                  ),
                  value: state.reduceAnimations,
                  onChanged: (value) {
                    context.read<AccessibilityBloc>().add(
                          ToggleReduceAnimations(value),
                        );
                    
                    // Announce change to screen reader
                    AccessibilityUtils.announce(
                      context,
                      'Reduce animations ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                  secondary: const Icon(Icons.animation),
                ),
              ),
              const Divider(),

              // Screen Reader Info
              Semantics(
                label: 'Screen reader information',
                child: ListTile(
                  leading: const Icon(Icons.accessibility_new),
                  title: const Text('Screen Reader'),
                  subtitle: Text(
                    AccessibilityUtils.isScreenReaderEnabled(context)
                        ? 'Active'
                        : 'Not detected',
                  ),
                  trailing: AccessibilityUtils.isScreenReaderEnabled(context)
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
              ),
              const Divider(),

              // Info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'About Accessibility',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'These settings help make the app more accessible. '
                        'The app also respects your device\'s system accessibility settings.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getTextSizeLabel(double scale) {
    if (scale < 0.9) return 'Extra Small';
    if (scale < 1.0) return 'Small';
    if (scale < 1.2) return 'Normal';
    if (scale < 1.4) return 'Large';
    if (scale < 1.7) return 'Extra Large';
    return 'Huge';
  }
}
