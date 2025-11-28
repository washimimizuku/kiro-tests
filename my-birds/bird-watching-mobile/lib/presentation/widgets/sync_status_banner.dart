import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';
import '../blocs/sync/sync_event.dart';
import '../../core/utils/accessibility_utils.dart';

/// Banner widget that displays sync status and allows manual sync trigger
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        // Don't show banner when idle
        if (state is SyncIdle) {
          return const SizedBox.shrink();
        }

        Color backgroundColor;
        IconData icon;
        String message;
        Widget? trailing;
        String semanticLabel;

        if (state is Syncing) {
          backgroundColor = Colors.blue.shade100;
          icon = Icons.sync;
          message = 'Syncing ${state.current} of ${state.total}...';
          semanticLabel = AccessibilityUtils.syncStatusLabel(
            pendingCount: state.total,
            isSyncing: true,
          );
          trailing = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (state is SyncComplete) {
          backgroundColor = Colors.green.shade100;
          icon = Icons.check_circle;
          message = '${state.synced} observation(s) synced successfully';
          semanticLabel = 'Sync complete: ${state.synced} observations synced successfully';
          trailing = null;
        } else if (state is SyncError) {
          backgroundColor = Colors.red.shade100;
          icon = Icons.error;
          message = 'Sync failed: ${state.message}';
          semanticLabel = AccessibilityUtils.syncStatusLabel(
            pendingCount: state.failed,
            error: state.message,
          );
          trailing = Semantics(
            label: 'Retry sync',
            button: true,
            child: TextButton(
              onPressed: () {
                context.read<SyncBloc>().add(const StartSync());
              },
              child: const Text('Retry'),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: semanticLabel,
          liveRegion: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Color.fromRGBO(
                    backgroundColor.red,
                    backgroundColor.green,
                    backgroundColor.blue,
                    0.5,
                  ),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
