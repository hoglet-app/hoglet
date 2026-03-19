import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});
  @override State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  String? _host;

  @override void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
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
        return RefreshIndicator(onRefresh: _load, child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: state.recordings.value.length,
          itemBuilder: (context, i) {
            final rec = state.recordings.value[i];
            final id = rec['id']?.toString() ?? '';
            final duration = (rec['recording_duration'] as num?)?.toInt() ?? 0;
            final person = rec['person'] as Map<String, dynamic>?;
            final name = person?['properties']?['email']?.toString() ?? person?['distinct_id']?.toString() ?? 'Anonymous';
            return Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
              child: ListTile(
                leading: const Icon(Icons.videocam, size: 22),
                title: Text(name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_formatDuration(duration), style: theme.textTheme.bodySmall),
                trailing: Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                onTap: () => _openRecording(id),
              ),
            );
          },
        ));
      }),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}
