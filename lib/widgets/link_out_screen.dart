import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkOutScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String url;

  const LinkOutScreen({super.key, required this.title, required this.icon, required this.description, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _launch(url),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in PostHog'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
