import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});
  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  String? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    _host = c.host;
    p.recordingsState.fetchRecordings(p.client, c.host, c.projectId, c.apiKey);
  }

  void _openRecording(String id) {
    if (_host == null) return;
    final url = Uri.parse('$_host/replay/$id');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).recordingsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Session Replay'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.recordings.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.recordings.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.recordings.value.isEmpty) return const EmptyState(icon: Icons.videocam_outlined, title: 'No recordings yet');

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.recordings.value.length,
            itemBuilder: (context, i) {
              final rec = state.recordings.value[i];
              return _RecordingCard(
                recording: rec,
                theme: theme,
                onTap: () => _openRecording(rec['id']?.toString() ?? ''),
              );
            },
          ),
        );
      }),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  final Map<String, dynamic> recording;
  final ThemeData theme;
  final VoidCallback onTap;

  const _RecordingCard({required this.recording, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final duration = (recording['recording_duration'] as num?)?.toInt() ?? 0;
    final person = recording['person'] as Map<String, dynamic>?;
    final properties = person?['properties'] as Map<String, dynamic>? ?? {};
    final email = properties['email']?.toString();
    final name = properties['name']?.toString() ?? email ?? person?['distinct_id']?.toString() ?? 'Anonymous';
    final startTime = recording['start_time']?.toString();
    final activeSeconds = (recording['active_seconds'] as num?)?.toInt();
    final clickCount = (recording['click_count'] as num?)?.toInt();
    final keypressCount = (recording['keypress_count'] as num?)?.toInt();
    final os = properties['\$os']?.toString();
    final browser = properties['\$browser']?.toString();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User + duration
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (startTime != null)
                          Text(
                            _formatTime(startTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                ],
              ),
              // Activity metrics
              const SizedBox(height: 10),
              Row(
                children: [
                  if (activeSeconds != null) ...[
                    _ActivityBadge(icon: Icons.touch_app, label: '${_formatDuration(activeSeconds)} active', theme: theme),
                    const SizedBox(width: 12),
                  ],
                  if (clickCount != null && clickCount > 0) ...[
                    _ActivityBadge(icon: Icons.mouse, label: '$clickCount clicks', theme: theme),
                    const SizedBox(width: 12),
                  ],
                  if (keypressCount != null && keypressCount > 0) ...[
                    _ActivityBadge(icon: Icons.keyboard, label: '$keypressCount keys', theme: theme),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  if (os != null || browser != null)
                    Text(
                      [os, browser].where((s) => s != null).join(' / '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  String _formatTime(String isoTime) {
    final dt = DateTime.tryParse(isoTime);
    if (dt == null) return isoTime;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

class _ActivityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _ActivityBadge({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }
}
