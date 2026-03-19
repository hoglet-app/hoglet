import 'package:flutter/material.dart';

import '../services/posthog_api_error.dart';

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, message) = _errorDetails();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _errorDetails() {
    if (error is NetworkError) {
      return (
        Icons.wifi_off,
        'No Connection',
        'Check your internet connection and try again.',
      );
    }
    if (error is AuthenticationError) {
      return (
        Icons.lock,
        'Authentication Failed',
        'Your API key may be invalid or expired.',
      );
    }
    if (error is RateLimitError) {
      final rl = error as RateLimitError;
      final retryText = rl.retryAfter != null
          ? 'Try again in ${rl.retryAfter!.inSeconds} seconds.'
          : 'Please wait a moment and try again.';
      return (Icons.timer, 'Too Many Requests', retryText);
    }
    if (error is PosthogApiError) {
      return (
        Icons.error_outline,
        'Something Went Wrong',
        (error as PosthogApiError).message,
      );
    }
    return (
      Icons.error_outline,
      'Something Went Wrong',
      error.toString(),
    );
  }
}
