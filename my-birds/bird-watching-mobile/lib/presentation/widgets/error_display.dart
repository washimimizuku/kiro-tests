import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/error_mapper.dart';

/// Widget to display error messages with retry option
class ErrorDisplay extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRetryable = ErrorMapper.isRetryable(error);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Icon(
            _getErrorIcon(),
            size: 64,
            color: _getErrorColor(),
          ),
          const SizedBox(height: 16),

          // Error message
          Text(
            ErrorMapper.getUserMessage(error),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _getErrorColor(),
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Error details
          if (showDetails && error.details != null)
            Text(
              error.details!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onDismiss != null)
                OutlinedButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              if (onDismiss != null && isRetryable && onRetry != null)
                const SizedBox(width: 12),
              if (isRetryable && onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    if (error is NetworkError) {
      return Icons.cloud_off;
    } else if (error is AuthenticationError) {
      return Icons.lock_outline;
    } else if (error is PhotoUploadError) {
      return Icons.image_not_supported;
    } else if (error is ValidationError) {
      return Icons.error_outline;
    } else if (error is ServerError) {
      return Icons.dns_outlined;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    if (error is NetworkError) {
      return Colors.orange;
    } else if (error is AuthenticationError) {
      return Colors.red;
    } else if (error is ValidationError) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }
}

/// Compact error banner widget
class ErrorBanner extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isRetryable = ErrorMapper.isRetryable(error);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _getBackgroundColor(),
      child: Row(
        children: [
          Icon(
            _getErrorIcon(),
            size: 20,
            color: _getIconColor(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ErrorMapper.getUserMessage(error),
              style: TextStyle(
                color: _getTextColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isRetryable && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: _getIconColor()),
              ),
            ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 20, color: _getIconColor()),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    if (error is NetworkError) {
      return Icons.cloud_off;
    } else if (error is AuthenticationError) {
      return Icons.lock_outline;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getBackgroundColor() {
    if (error is NetworkError) {
      return Colors.orange[100]!;
    } else if (error is AuthenticationError) {
      return Colors.red[100]!;
    } else {
      return Colors.red[100]!;
    }
  }

  Color _getIconColor() {
    if (error is NetworkError) {
      return Colors.orange[800]!;
    } else if (error is AuthenticationError) {
      return Colors.red[800]!;
    } else {
      return Colors.red[800]!;
    }
  }

  Color _getTextColor() {
    if (error is NetworkError) {
      return Colors.orange[900]!;
    } else if (error is AuthenticationError) {
      return Colors.red[900]!;
    } else {
      return Colors.red[900]!;
    }
  }
}

/// Show error snackbar
void showErrorSnackBar(BuildContext context, AppError error, {VoidCallback? onRetry}) {
  final isRetryable = ErrorMapper.isRetryable(error);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ErrorMapper.getUserMessage(error)),
      backgroundColor: error is NetworkError ? Colors.orange : Colors.red,
      action: isRetryable && onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
      duration: const Duration(seconds: 4),
    ),
  );
}

/// Show error dialog
Future<void> showErrorDialog(
  BuildContext context,
  AppError error, {
  VoidCallback? onRetry,
  bool showDetails = true,
}) {
  final isRetryable = ErrorMapper.isRetryable(error);

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            error is NetworkError ? Icons.cloud_off : Icons.error_outline,
            color: error is NetworkError ? Colors.orange : Colors.red,
          ),
          const SizedBox(width: 12),
          const Text('Error'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ErrorMapper.getUserMessage(error),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (showDetails && error.details != null) ...[
            const SizedBox(height: 8),
            Text(
              error.details!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (isRetryable && onRetry != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
      ],
    ),
  );
}
