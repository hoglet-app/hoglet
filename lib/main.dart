import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const HogletApp());
}

class HogletApp extends StatelessWidget {
  const HogletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoglet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HogletHomePage(),
    );
  }
}

class HogletHomePage extends StatefulWidget {
  const HogletHomePage({super.key});

  @override
  State<HogletHomePage> createState() => _HogletHomePageState();
}

class _HogletHomePageState extends State<HogletHomePage>
    with WidgetsBindingObserver {
  static const _storage = FlutterSecureStorage();
  static const _keyHost = 'posthog_host';
  static const _keyHostMode = 'posthog_host_mode';
  static const _keyCustomHost = 'posthog_custom_host';
  static const _keyProjectId = 'posthog_project_id';
  static const _keyApiKey = 'posthog_personal_api_key';

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
      final uri = Uri.parse('$host/api/projects/$projectId/query/');
      final body = {
        'name': 'hoglet_live_events',
        'query': {
          'kind': 'HogQLQuery',
          'query':
              'SELECT uuid, event, distinct_id, timestamp, properties FROM events ORDER BY timestamp DESC LIMIT 100',
        },
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        _setStatus('Request failed: ${response.statusCode} ${response.reasonPhrase}');
        return;
      }

      final decoded = jsonDecode(response.body);
      final results = decoded is Map && decoded['results'] is List
          ? decoded['results'] as List
          : <dynamic>[];

      final parsed = <EventItem>[];
      for (final row in results) {
        if (row is List && row.length >= 5) {
          parsed.add(EventItem.fromList(row));
        } else if (row is Map) {
          parsed.add(EventItem.fromMap(row));
        }
      }

      if (!mounted) return;

      setState(() {
        _events
          ..clear()
          ..addAll(parsed);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoglet'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSettingsCard(),
            const SizedBox(height: 16),
            _buildActionsRow(),
            const SizedBox(height: 16),
            _buildStatus(),
            const SizedBox(height: 8),
            _buildEventsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                  icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _showApiKey = !_showApiKey;
                    });
                  },
                ),
              ),
              onChanged: (_) => _persistSettings(),
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _fetchEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Fetch Events'),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            const Text('Auto'),
            Switch(
              value: _autoRefresh,
              onChanged: _isLoading ? null : _toggleAutoRefresh,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatus() {
    if (_statusMessage == null) return const SizedBox.shrink();
    return Text(
      _statusMessage!,
      style: const TextStyle(color: Colors.black54),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return const Text('No events loaded yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest events (${_events.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final event in _events) _buildEventTile(event),
      ],
    );
  }

  Widget _buildEventTile(EventItem event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(event.eventName),
        subtitle: Text('${event.distinctId} • ${event.timestampLabel}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showModalBottomSheet(
            context: context,
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
      ),
    );
  }
}

class EventItem {
  EventItem({
    required this.uuid,
    required this.eventName,
    required this.distinctId,
    required this.timestamp,
    required this.properties,
  });

  final String uuid;
  final String eventName;
  final String distinctId;
  final DateTime? timestamp;
  final Map<String, dynamic> properties;

  factory EventItem.fromList(List<dynamic> row) {
    return EventItem(
      uuid: row[0]?.toString() ?? '',
      eventName: row[1]?.toString() ?? '',
      distinctId: row[2]?.toString() ?? '',
      timestamp: _parseTimestamp(row[3]),
      properties: _parseProperties(row[4]),
    );
  }

  factory EventItem.fromMap(Map<dynamic, dynamic> row) {
    return EventItem(
      uuid: row['uuid']?.toString() ?? '',
      eventName: row['event']?.toString() ?? '',
      distinctId: row['distinct_id']?.toString() ?? '',
      timestamp: _parseTimestamp(row['timestamp']),
      properties: _parseProperties(row['properties']),
    );
  }

  String get timestampLabel {
    if (timestamp == null) return 'Unknown time';
    final local = timestamp!.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} '
        '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}:${_twoDigits(local.second)}';
  }

  String get prettyDetails {
    final buffer = StringBuffer();
    buffer.writeln('UUID: $uuid');
    buffer.writeln('Event: $eventName');
    buffer.writeln('Distinct ID: $distinctId');
    buffer.writeln('Timestamp: ${timestamp?.toIso8601String() ?? 'unknown'}');
    buffer.writeln('Properties:');
    buffer.writeln(const JsonEncoder.withIndent('  ').convert(properties));
    return buffer.toString();
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic> _parseProperties(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return {};
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
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
