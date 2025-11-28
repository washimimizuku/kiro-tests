import 'package:flutter/material.dart';

/// Widget that displays an offline mode indicator banner
class OfflineModeIndicator extends StatelessWidget {
  final bool isOffline;
  final int? pendingSyncCount;
  final VoidCallback? onSyncNow;
  final bool showSyncButton;

  const OfflineModeIndicator({
    super.key,
    required this.isOffline,
    this.pendingSyncCount,
    this.onSyncNow,
    this.showSyncButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && (pendingSyncCount == null || pendingSyncCount == 0)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOffline ? Colors.orange[100] : Colors.blue[100],
        border: Border(
          bottom: BorderSide(
            color: isOffline ? Colors.orange[300]! : Colors.blue[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.sync,
            size: 20,
            color: isOffline ? Colors.orange[800] : Colors.blue[800],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOffline ? 'Offline Mode' : 'Sync Pending',
                  style: TextStyle(
                    color: isOffline ? Colors.orange[900] : Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (pendingSyncCount != null && pendingSyncCount! > 0)
                  Text(
                    '$pendingSyncCount ${pendingSyncCount == 1 ? 'observation' : 'observations'} pending sync',
                    style: TextStyle(
                      color: isOffline ? Colors.orange[800] : Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (!isOffline && showSyncButton && onSyncNow != null && pendingSyncCount != null && pendingSyncCount! > 0)
            TextButton(
              onPressed: onSyncNow,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Sync Now'),
            ),
        ],
      ),
    );
  }
}

/// Compact offline indicator for app bar
class OfflineBadge extends StatelessWidget {
  final bool isOffline;

  const OfflineBadge({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cloud_off, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay that dims the screen when offline with a message
class OfflineOverlay extends StatelessWidget {
  final bool isOffline;
  final Widget child;
  final String? message;

  const OfflineOverlay({
    super.key,
    required this.isOffline,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isOffline)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message ?? 'You are offline',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This feature requires an internet connection',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin to add offline mode awareness to widgets
mixin OfflineModeMixin {
  /// Check if a feature should be disabled in offline mode
  bool isFeatureDisabled(bool isOffline, {required bool requiresOnline}) {
    return isOffline && requiresOnline;
  }

  /// Show a message when trying to use an online-only feature while offline
  void showOfflineMessage(BuildContext context, {String? customMessage}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          customMessage ?? 'This feature is not available offline',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
