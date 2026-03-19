import 'package:flutter/material.dart';

import '../../models/host_mode.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();

  final _customHostController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _apiKeyController = TextEditingController();

  HostMode _hostMode = HostMode.us;
  bool _showApiKey = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customHostController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final hostMode = await _storage.read(StorageService.keyHostMode) ?? 'us';
    final customHost = await _storage.read(StorageService.keyCustomHost) ?? '';
    final projectId = await _storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await _storage.read(StorageService.keyApiKey) ?? '';

    if (!mounted) return;
    setState(() {
      _hostMode = HostModeX.fromStorage(hostMode);
      _customHostController.text = customHost;
      _projectIdController.text = projectId;
      _apiKeyController.text = apiKey;
      _loaded = true;
    });
  }

  Future<void> _saveSettings() async {
    final host = _effectiveHost;
    final projectId = _projectIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
      _showSnackBar('Please fill host, project ID, and API key.');
      return;
    }

    await _storage.write(StorageService.keyHost, host);
    await _storage.write(StorageService.keyHostMode, _hostMode.storageValue);
    await _storage.write(StorageService.keyCustomHost, _customHostController.text.trim());
    await _storage.write(StorageService.keyProjectId, projectId);
    await _storage.write(StorageService.keyApiKey, apiKey);

    if (!mounted) return;
    _showSnackBar('Settings saved.');
  }

  String get _effectiveHost {
    if (_hostMode == HostMode.custom) {
      var host = _customHostController.text.trim();
      if (host.isNotEmpty && !host.startsWith('http://') && !host.startsWith('https://')) {
        host = 'https://$host';
      }
      return host.replaceAll(RegExp(r'/+$'), '');
    }
    return _hostMode.hostUrl;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Connection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<HostMode>(
          value: _hostMode,
          decoration: const InputDecoration(labelText: 'Host Region'),
          items: const [
            DropdownMenuItem(value: HostMode.us, child: Text('US Cloud (us.posthog.com)')),
            DropdownMenuItem(value: HostMode.eu, child: Text('EU Cloud (eu.posthog.com)')),
            DropdownMenuItem(value: HostMode.custom, child: Text('Custom Domain')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _hostMode = value);
          },
        ),
        if (_hostMode == HostMode.custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customHostController,
            decoration: const InputDecoration(
              labelText: 'Custom Host',
              hintText: 'https://your.posthog.domain',
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _projectIdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Project ID'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKeyController,
          obscureText: !_showApiKey,
          decoration: InputDecoration(
            labelText: 'Personal API Key',
            suffixIcon: IconButton(
              icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showApiKey = !_showApiKey),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save Settings'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your personal API key is stored securely on this device.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 32),
        const Text(
          'About',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hoglet — PostHog Mobile Client\nVersion 1.0.0',
          style: TextStyle(color: Color(0xFF6F6A63)),
        ),
      ],
    );
  }
}
