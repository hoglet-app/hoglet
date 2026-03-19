import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../di/providers.dart';

class OpenInPostHogButton extends StatelessWidget {
  final String path;

  const OpenInPostHogButton({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.open_in_new, size: 20),
      onPressed: () => _open(context),
      tooltip: 'Open in PostHog',
    );
  }

  Future<void> _open(BuildContext context) async {
    final c = await AppProviders.of(context).storage.readCredentials();
    if (c == null) return;
    final url = Uri.parse('${c.host}$path');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
