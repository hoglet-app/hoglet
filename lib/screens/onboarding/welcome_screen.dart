import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../routing/route_names.dart';

enum HostRegion { usCloud, euCloud, custom }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  HostRegion _region = HostRegion.usCloud;
  final _apiKeyController = TextEditingController();
  final _customHostController = TextEditingController();
  bool _isLoading = false;
  bool _obscureKey = true;
  String? _error;
  List<Map<String, dynamic>>? _projects;
  String? _selectedProjectId;

  String get _host {
    switch (_region) {
      case HostRegion.usCloud:
        return 'https://us.posthog.com';
      case HostRegion.euCloud:
        return 'https://eu.posthog.com';
      case HostRegion.custom:
        return _customHostController.text.trim();
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customHostController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _error = 'Please enter your API key');
      return;
    }
    if (_region == HostRegion.custom && _customHostController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your PostHog host URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _projects = null;
      _selectedProjectId = null;
    });

    try {
      final client = AppProviders.of(context).client;
      final projects = await client.fetchProjects(_host, apiKey);
      setState(() {
        _projects = projects;
        if (projects.length == 1) {
          _selectedProjectId = projects.first['id']?.toString();
        }
      });
    } catch (e) {
      setState(() => _error = 'Connection failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connect() async {
    if (_selectedProjectId == null) {
      setState(() => _error = 'Please select a project');
      return;
    }

    final storage = AppProviders.of(context).storage;
    await storage.saveCredentials(
      host: _host,
      projectId: _selectedProjectId!,
      apiKey: _apiKeyController.text.trim(),
    );

    if (mounted) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                '🦔',
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to Hoglet',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connect to your PostHog instance',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Region picker
              Text('Region', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<HostRegion>(
                segments: const [
                  ButtonSegment(value: HostRegion.usCloud, label: Text('US Cloud')),
                  ButtonSegment(value: HostRegion.euCloud, label: Text('EU Cloud')),
                  ButtonSegment(value: HostRegion.custom, label: Text('Self-hosted')),
                ],
                selected: {_region},
                onSelectionChanged: (selected) =>
                    setState(() => _region = selected.first),
              ),

              // Custom host input
              if (_region == HostRegion.custom) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customHostController,
                  decoration: const InputDecoration(
                    labelText: 'PostHog URL',
                    hintText: 'https://posthog.example.com',
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],

              const SizedBox(height: 24),

              // API key input
              Text('Personal API Key', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  hintText: 'phx_...',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                obscureText: _obscureKey,
              ),

              const SizedBox(height: 24),

              // Test connection button
              ElevatedButton(
                onPressed: _isLoading ? null : _testConnection,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Test Connection'),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],

              // Project selector
              if (_projects != null && _projects!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Select Project', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: const InputDecoration(
                    hintText: 'Choose a project',
                  ),
                  items: _projects!
                      .map((p) => DropdownMenuItem(
                            value: p['id']?.toString(),
                            child: Text(p['name']?.toString() ?? 'Unknown'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedProjectId = value),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _selectedProjectId == null ? null : _connect,
                  child: const Text('Connect'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
