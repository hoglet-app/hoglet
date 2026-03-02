import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/event_item.dart';
import '../services/posthog_client.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  static const _storage = FlutterSecureStorage();
  static const _keyHost = 'posthog_host';
  static const _keyHostMode = 'posthog_host_mode';
  static const _keyCustomHost = 'posthog_custom_host';
  static const _keyProjectId = 'posthog_project_id';
  static const _keyApiKey = 'posthog_personal_api_key';

  final _client = PosthogClient();

  final _customHostController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _apiKeyController = TextEditingController();

  final List<EventItem> _events = [];
  bool _isLoading = false;
  bool _autoRefresh = false;
  bool _showApiKey = false;
  String? _statusMessage;
  Timer? _timer;
  HostMode _hostMode = HostMode.us;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _customHostController.dispose();
    _projectIdController.dispose();
    _apiKeyController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _persistSettings();
    }
  }

  Future<void> _loadSettings() async {
    final host = await _storage.read(key: _keyHost) ?? '';
    final hostMode = await _storage.read(key: _keyHostMode) ?? 'us';
    final customHost = await _storage.read(key: _keyCustomHost) ?? '';
    final projectId = await _storage.read(key: _keyProjectId) ?? '';
    final apiKey = await _storage.read(key: _keyApiKey) ?? '';

    if (!mounted) return;

    setState(() {
      _hostMode = HostModeX.fromStorage(hostMode);
      _customHostController.text = customHost;
      _projectIdController.text = projectId;
      _apiKeyController.text = apiKey;
    });

    if (host.isNotEmpty && _hostMode != HostMode.custom) {
      _customHostController.text = '';
    }
  }

  Future<void> _saveSettings() async {
    final host = _normalizeHost(_effectiveHost);
    final projectId = _projectIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
      _setStatus('Please fill host, project ID, and API key.');
      return;
    }

    await _storage.write(key: _keyHost, value: host);
    await _storage.write(key: _keyHostMode, value: _hostMode.storageValue);
    await _storage.write(
      key: _keyCustomHost,
      value: _customHostController.text.trim(),
    );
    await _storage.write(key: _keyProjectId, value: projectId);
    await _storage.write(key: _keyApiKey, value: apiKey);

    if (!mounted) return;

    _setStatus('Saved settings.');
  }

  Future<void> _persistSettings() async {
    await _storage.write(key: _keyHostMode, value: _hostMode.storageValue);
    await _storage.write(
      key: _keyCustomHost,
      value: _customHostController.text.trim(),
    );
    await _storage.write(
      key: _keyProjectId,
      value: _projectIdController.text.trim(),
    );
    await _storage.write(
      key: _keyApiKey,
      value: _apiKeyController.text.trim(),
    );
    await _storage.write(key: _keyHost, value: _normalizeHost(_effectiveHost));
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
    });
  }

  void _toggleAutoRefresh(bool value) {
    setState(() {
      _autoRefresh = value;
    });

    _timer?.cancel();

    if (value) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        _fetchEvents();
      });
    }
  }

  String _normalizeHost(String input) {
    var trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  String get _effectiveHost {
    switch (_hostMode) {
      case HostMode.us:
        return 'https://us.posthog.com';
      case HostMode.eu:
        return 'https://eu.posthog.com';
      case HostMode.custom:
        return _customHostController.text;
    }
  }

  Future<void> _fetchEvents() async {
    final host = _normalizeHost(_effectiveHost);
    final projectId = _projectIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
      _setStatus('Please fill host, project ID, and API key.');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final events = await _client.fetchEvents(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );

      if (!mounted) return;

      setState(() {
        _events
          ..clear()
          ..addAll(events);
      });

      _setStatus('Fetched ${_events.length} events.');
    } catch (error) {
      _setStatus('Failed to fetch events: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F4EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Connection Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HostMode>(
                value: _hostMode,
                decoration: const InputDecoration(
                  labelText: 'Host Region',
                ),
                items: const [
                  DropdownMenuItem(
                    value: HostMode.us,
                    child: Text('US Cloud (us.posthog.com)'),
                  ),
                  DropdownMenuItem(
                    value: HostMode.eu,
                    child: Text('EU Cloud (eu.posthog.com)'),
                  ),
                  DropdownMenuItem(
                    value: HostMode.custom,
                    child: Text('Custom Domain'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _hostMode = value;
                  });
                  _persistSettings();
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
                  onChanged: (_) => _persistSettings(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _projectIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Project ID',
                ),
                onChanged: (_) => _persistSettings(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                obscureText: !_showApiKey,
                decoration: InputDecoration(
                  labelText: 'Personal API Key',
                  suffixIcon: IconButton(
                    icon:
                        Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showApiKey = !_showApiKey;
                      });
                    },
                  ),
                ),
                onChanged: (_) => _persistSettings(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Admin-only: this app stores your personal API key on the device.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F4EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F4EF),
          elevation: 0,
          title: const Text('Hoglet'),
          actions: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bolt),
              label: const Text('Quick start'),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettingsSheet,
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFF15A24),
            labelColor: Color(0xFF1C1B19),
            unselectedLabelColor: Color(0xFF6F6A63),
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Sessions'),
              Tab(text: 'Live'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEventsTab(),
            _buildPlaceholder('Sessions view coming soon.'),
            _buildPlaceholder('Live view coming soon.'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, color: Color(0xFF1C1B19)),
            const SizedBox(width: 8),
            const Text(
              'Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Chip(
              label: const Text('PostHog default view'),
              avatar: const Icon(Icons.tune, size: 16),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE3DED6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Explore your events or see real-time events from your app or website.',
          style: TextStyle(color: Color(0xFF6F6A63)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('Last hour'),
            _filterChip('Select an event'),
            _filterChip('Filter', icon: Icons.add),
            _filterChip('Filter out internal and test users', isToggle: true),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _fetchEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1B19),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFE3DED6)),
              ),
            ),
            const Spacer(),
            _headerButton('Configure columns', Icons.view_column_outlined),
            const SizedBox(width: 8),
            _headerButton('Export', Icons.file_download_outlined),
            const SizedBox(width: 8),
            _headerButton('Open as new insight', Icons.open_in_new),
          ],
        ),
        const SizedBox(height: 16),
        _buildEventsTable(),
      ],
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF6F6A63)),
      ),
    );
  }

  Widget _filterChip(String text, {IconData? icon, bool isToggle = false}) {
    return Chip(
      label: Text(text),
      avatar: icon != null
          ? Icon(icon, size: 16, color: const Color(0xFF1C1B19))
          : null,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE3DED6)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF1C1B19)),
    );
  }

  Widget _headerButton(String text, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1C1B19),
        side: const BorderSide(color: Color(0xFFE3DED6)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEventsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3DED6)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFE3DED6)),
          if (_isLoading && _events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No events loaded yet.'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _events.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE3DED6)),
              itemBuilder: (context, index) {
                final event = _events[index];
                return _buildEventRow(event);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('EVENT')),
          Expanded(flex: 2, child: Text('PERSON')),
          Expanded(flex: 3, child: Text('URL / SCREEN')),
          Expanded(child: Text('LIBRARY')),
          Expanded(child: Text('TIME')),
        ],
      ),
    );
  }

  Widget _buildEventRow(EventItem event) {
    return ListTile(
      dense: true,
      title: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(event.eventName),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFDAD1C3),
                  child: Text(
                    event.personInitial,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.distinctId,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              event.urlLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: Text(event.libraryLabel)),
          Expanded(child: Text(event.timeAgoLabel)),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFFF5F4EF),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(event.prettyDetails),
              ),
            );
          },
        );
      },
    );
  }
}

enum HostMode {
  us,
  eu,
  custom,
}

extension HostModeX on HostMode {
  String get storageValue {
    switch (this) {
      case HostMode.us:
        return 'us';
      case HostMode.eu:
        return 'eu';
      case HostMode.custom:
        return 'custom';
    }
  }

  static HostMode fromStorage(String raw) {
    switch (raw) {
      case 'eu':
        return HostMode.eu;
      case 'custom':
        return HostMode.custom;
      case 'us':
      default:
        return HostMode.us;
    }
  }
}
