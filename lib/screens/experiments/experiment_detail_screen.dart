import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/open_in_posthog.dart';
import '../../widgets/shimmer_list.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;
  const ExperimentDetailScreen({super.key, required this.experimentId});
  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    final id = int.tryParse(widget.experimentId); if (id == null) return;
    p.experimentsState.fetchExperiment(p.client, c.host, c.projectId, c.apiKey, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).experimentsState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final exp = state.experiment.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(exp?.name ?? 'Experiment'),
          actions: [
            OpenInPostHogButton(path: '/experiments/${widget.experimentId}'),
          ],
        ),
        body: () {
          if (isLoading && exp == null) return const ShimmerList(itemCount: 4);
          if (error != null && exp == null) return ErrorView(error: error, onRetry: _load);
          if (exp == null) return const Center(child: Text('Experiment not found'));

          final statusColor = exp.isComplete ? Colors.green : exp.isRunning ? Colors.orange : Colors.grey;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exp.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
                                exp.status,
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (exp.results?.isSignificant == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('Significant', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (exp.description != null && exp.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(exp.description!, style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),

                // Timeline
                if (exp.startDate != null || exp.endDate != null) ...[
                  const SizedBox(height: 16),
                  Text('TIMELINE', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          if (exp.startDate != null)
                            _DetailRow(
                              icon: Icons.play_arrow,
                              label: 'Started',
                              value: _formatDate(exp.startDate!),
                              theme: theme,
                            ),
                          if (exp.endDate != null)
                            _DetailRow(
                              icon: Icons.stop,
                              label: 'Ended',
                              value: _formatDate(exp.endDate!),
                              theme: theme,
                            ),
                          if (exp.startDate != null && exp.endDate == null)
                            _DetailRow(
                              icon: Icons.timer,
                              label: 'Running for',
                              value: _durationStr(exp.startDate!),
                              theme: theme,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Linked flag
                if (exp.featureFlagKey != null) ...[
                  const SizedBox(height: 16),
                  Text('LINKED FLAG', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.flag, size: 20),
                      title: Text(exp.featureFlagKey!, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],

                // Variants with visual distribution
                if (exp.variants.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('VARIANTS', style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  )),
                  const SizedBox(height: 8),
                  // Distribution bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: exp.variants.asMap().entries.map((e) {
                          final color = _variantColor(e.key);
                          return Expanded(
                            flex: e.value.rolloutPercentage > 0 ? e.value.rolloutPercentage : 1,
                            child: Container(
                              color: color,
                              child: Center(
                                child: Text(
                                  '${e.value.rolloutPercentage}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exp.variants.asMap().entries.map((e) {
                    final v = e.value;
                    final color = _variantColor(e.key);
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name ?? v.key, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(v.key, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                            Text(
                              '${v.rolloutPercentage}%',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }(),
      );
    });
  }

  Color _variantColor(int index) {
    const colors = [Colors.blue, Colors.orange, Colors.teal, Colors.purple, Colors.pink, Colors.indigo];
    return colors[index % colors.length];
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _durationStr(DateTime start) {
    final diff = DateTime.now().difference(start);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    return '${diff.inMinutes} min';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  const _DetailRow({required this.icon, required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
