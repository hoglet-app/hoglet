import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/open_in_posthog.dart';
import '../../widgets/shimmer_list.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});
  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    final id = int.tryParse(widget.alertId);
    if (id == null) return;
    p.alertsState.fetchAlert(p.client, c.host, c.projectId, c.apiKey, id);
  }

  Future<void> _dismiss() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    final id = int.tryParse(widget.alertId);
    if (id == null) return;
    try {
      await p.alertsState.dismissAlert(p.client, c.host, c.projectId, c.apiKey, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert dismissed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).alertsState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final alert = state.alert.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(alert?.name ?? 'Alert'),
          actions: [OpenInPostHogButton(path: '/alerts/${widget.alertId}')],
        ),
        body: () {
          if (isLoading && alert == null) return const ShimmerList(itemCount: 3);
          if (error != null && alert == null) return ErrorView(error: error, onRetry: _load);
          if (alert == null) return const Center(child: Text('Alert not found'));

          final statusColor = alert.isFiring ? Colors.red : alert.status == 'snoozed' ? Colors.orange : Colors.green;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    alert.isFiring ? Icons.warning : alert.status == 'snoozed' ? Icons.snooze : Icons.check_circle,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    alert.status[0].toUpperCase() + alert.status.substring(1),
                                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Linked insight
                if (alert.insightId != null || alert.insightName != null) ...[
                  const SizedBox(height: 16),
                  Text('LINKED INSIGHT', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.insights, size: 20),
                      title: Text(alert.insightName ?? 'Insight #${alert.insightId}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],

                // Threshold config
                if (alert.threshold != null) ...[
                  const SizedBox(height: 16),
                  Text('THRESHOLD', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          if (alert.threshold!['type'] != null)
                            _DetailRow(label: 'Type', value: alert.threshold!['type'].toString(), theme: theme),
                          if (alert.threshold!['configuration'] is Map) ...[
                            for (final entry in (alert.threshold!['configuration'] as Map).entries)
                              _DetailRow(label: entry.key.toString(), value: entry.value.toString(), theme: theme),
                          ],
                          if (alert.threshold!['value'] != null)
                            _DetailRow(label: 'Value', value: alert.threshold!['value'].toString(), theme: theme),
                        ],
                      ),
                    ),
                  ),
                ],

                // Details
                const SizedBox(height: 16),
                Text('DETAILS', style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _DetailRow(label: 'ID', value: alert.id.toString(), theme: theme),
                        if (alert.createdAt != null)
                          _DetailRow(
                            label: 'Created',
                            value: '${alert.createdAt!.year}-${alert.createdAt!.month.toString().padLeft(2, '0')}-${alert.createdAt!.day.toString().padLeft(2, '0')}',
                            theme: theme,
                          ),
                      ],
                    ),
                  ),
                ),

                // Dismiss button
                if (alert.isFiring) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _dismiss,
                      icon: const Icon(Icons.snooze),
                      label: const Text('Dismiss Alert'),
                    ),
                  ),
                ],
              ],
            ),
          );
        }(),
      );
    });
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _DetailRow({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
