import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _projectName;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final p = AppProviders.of(context);
    final credentials = await p.storage.readCredentials();
    String? projectName;
    if (credentials != null) {
      try {
        final projects = await p.client.fetchProjects(credentials.host, credentials.apiKey);
        final match = projects.where((proj) => proj['id']?.toString() == credentials.projectId).toList();
        if (match.isNotEmpty) {
          projectName = match.first['name']?.toString();
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _host = credentials?.host;
        _projectId = credentials?.projectId;
        _projectName = projectName;
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AppProviders.of(context).storage.clearCredentials();
      if (mounted) context.goNamed(RouteNames.welcome);
    }
  }

  Future<void> _openPostHog() async {
    if (_host == null) return;
    await launchUrl(Uri.parse(_host!), mode: LaunchMode.externalApplication);
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
                _SectionHeader('PROJECT'),
                if (_projectName != null)
                  ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: const Text('Project'),
                    subtitle: Text(_projectName!),
                  ),
                ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Host'),
                  subtitle: Text(_host ?? 'Not connected'),
                ),
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: const Text('Project ID'),
                  subtitle: Text(_projectId ?? 'Not set'),
                ),
                if (_host != null)
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: const Text('Open PostHog Web'),
                    subtitle: Text(_host!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                    onTap: _openPostHog,
                  ),
                const Divider(),
                _SectionHeader('APPEARANCE'),
                SwitchListTile(
                  secondary: Icon(
                    AppProviders.of(context).themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  value: AppProviders.of(context).themeMode == ThemeMode.dark,
                  onChanged: (_) => AppProviders.of(context).onToggleTheme(),
                ),
                const Divider(),
                _SectionHeader('ABOUT'),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Hoglet'),
                  subtitle: Text('v1.0.0 — PostHog Mobile Client'),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Features'),
                  subtitle: Text(
                    'Dashboards, Insights, Flags, Experiments, Surveys, '
                    'Persons, Cohorts, Groups, Error Tracking, Alerts, '
                    'Web Analytics, Revenue Analytics, LLM Analytics, '
                    'Session Replay, SQL Editor, Annotations, and more',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
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
                const SizedBox(height: 32),
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
