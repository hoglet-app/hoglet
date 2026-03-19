import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/stack_trace_view.dart';

class ErrorDetailScreen extends StatefulWidget {
  final String errorId;
  const ErrorDetailScreen({super.key, required this.errorId});
  @override
  State<ErrorDetailScreen> createState() => _ErrorDetailScreenState();
}

class _ErrorDetailScreenState extends State<ErrorDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.errorTrackingState.fetchError(p.client, c.host, c.projectId, c.apiKey, widget.errorId);
  }

  Future<void> _updateStatus(String status) async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    try {
      await p.errorTrackingState.updateStatus(p.client, c.host, c.projectId, c.apiKey, widget.errorId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'resolved' ? 'Error marked as resolved' : 'Error reopened')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _openInPostHog() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    final url = Uri.parse('${c.host}/error_tracking/${widget.errorId}');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).errorTrackingState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final err = state.errorDetail.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(err?.title ?? 'Error'),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: _openInPostHog,
              tooltip: 'Open in PostHog',
            ),
          ],
        ),
        body: () {
          if (isLoading && err == null) return const ShimmerList(itemCount: 4);
          if (error != null && err == null) return ErrorView(error: error, onRetry: _load);
          if (err == null) return const Center(child: Text('Error not found'));

          final stackTrace = err.raw['stack_trace']?.toString() ?? err.raw['exception']?.toString();
          final statusColor = err.status == 'active' ? Colors.red : err.status == 'resolved' ? Colors.green : Colors.orange;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Title & status
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          err.title ?? err.fingerprint,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                err.status[0].toUpperCase() + err.status.substring(1),
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(icon: Icons.repeat, label: 'Occurrences', value: '${err.occurrences}', theme: theme)),
                    const SizedBox(width: 8),
                    Expanded(child: _StatCard(icon: Icons.people, label: 'Users', value: err.affectedUsers != null ? '${err.affectedUsers}' : '—', theme: theme)),
                  ],
                ),

                // Timeline
                const SizedBox(height: 16),
                Text('TIMELINE', style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        if (err.firstSeen != null)
                          _TimelineRow(icon: Icons.first_page, label: 'First seen', date: err.firstSeen!, theme: theme),
                        if (err.lastSeen != null)
                          _TimelineRow(icon: Icons.last_page, label: 'Last seen', date: err.lastSeen!, theme: theme),
                        if (err.lastSeen != null && err.firstSeen != null)
                          _InfoRow(
                            label: 'Duration',
                            value: _durationStr(err.firstSeen!, err.lastSeen!),
                            theme: theme,
                          ),
                      ],
                    ),
                  ),
                ),

                // Fingerprint
                const SizedBox(height: 16),
                Text('FINGERPRINT', style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      err.fingerprint,
                      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),

                // Stack trace
                if (stackTrace != null && stackTrace.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('STACK TRACE', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  StackTraceView(stackTrace: stackTrace),
                ],

                // Actions
                const SizedBox(height: 24),
                if (err.status == 'active')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus('resolved'),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Mark as Resolved'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus('active'),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reopen Error'),
                    ),
                  ),
              ],
            ),
          );
        }(),
      );
    });
  }

  String _durationStr(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    return '${diff.inMinutes} min';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  const _StatCard({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  final ThemeData theme;
  const _TimelineRow({required this.icon, required this.label, required this.date, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          Text(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _InfoRow({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.timelapse, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
