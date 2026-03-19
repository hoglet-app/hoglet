import 'package:flutter/material.dart';
import '../services/posthog_api_error.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = _errorContent();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF6F6A63)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1B19),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF6F6A63)),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
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

  (IconData, String, String) _errorContent() {
    if (error is NetworkError) {
      return (Icons.wifi_off, 'No connection', (error as NetworkError).message);
    }
    if (error is AuthenticationError) {
      return (Icons.lock_outline, 'Authentication failed', 'Check your API key and try again.');
    }
    if (error is RateLimitError) {
      final e = error as RateLimitError;
      final msg = e.retryAfterSeconds != null
          ? 'Too many requests. Try again in ${e.retryAfterSeconds}s.'
          : 'Too many requests. Try again later.';
      return (Icons.speed, 'Rate limited', msg);
    }
    if (error is PosthogApiError) {
      return (Icons.error_outline, 'Error', (error as PosthogApiError).message);
    }
    return (Icons.error_outline, 'Something went wrong', error.toString());
  }
}
