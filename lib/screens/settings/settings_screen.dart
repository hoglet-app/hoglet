import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../routing/route_names.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _host;
  String? _projectId;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = AppProviders.of(context).storage;
    final credentials = await storage.readCredentials();
    if (mounted) {
      setState(() {
        _host = credentials?.host;
        _projectId = credentials?.projectId;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('This will clear your connection settings. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppProviders.of(context).storage.clearCredentials();
      if (mounted) {
        context.goNamed(RouteNames.welcome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _SectionHeader('CONNECTION'),
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Host'),
                  subtitle: Text(_host ?? 'Not connected'),
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Project ID'),
                  subtitle: Text(_projectId ?? 'Not set'),
                ),
                const Divider(),
                _SectionHeader('ABOUT'),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Hoglet'),
                  subtitle: const Text('v1.0.0 — PostHog Mobile Client'),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
      ),
    );
  }
}
