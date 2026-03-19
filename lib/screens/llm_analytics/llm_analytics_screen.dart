import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../state/llm_analytics_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class LlmAnalyticsScreen extends StatefulWidget {
  const LlmAnalyticsScreen({super.key});
  @override
  State<LlmAnalyticsScreen> createState() => _LlmAnalyticsScreenState();
}

class _LlmAnalyticsScreenState extends State<LlmAnalyticsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.llmAnalyticsState.fetchAnalytics(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).llmAnalyticsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LLM Analytics'),
        leading: const BackButton(),
      ),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.models.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.models.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.models.value.isEmpty) {
          return const EmptyState(
            icon: Icons.smart_toy_outlined,
            title: 'No LLM data yet',
            message: 'Send \$ai_generation events to see analytics here',
          );
        }

        // Compute totals
        final models = state.models.value;
        final totalGens = models.fold<int>(0, (sum, m) => sum + m.totalGenerations);
        final totalTokens = models.fold<int>(0, (sum, m) => sum + m.totalTokens);
        final totalCost = models.fold<double>(0, (sum, m) => sum + m.totalCost);

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              Text('LAST 7 DAYS', style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MetricCard(label: 'Generations', value: _formatNum(totalGens), icon: Icons.auto_awesome, theme: theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricCard(label: 'Tokens', value: _formatNum(totalTokens), icon: Icons.token, theme: theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricCard(label: 'Cost', value: '\$${totalCost.toStringAsFixed(2)}', icon: Icons.attach_money, theme: theme)),
                ],
              ),
              const SizedBox(height: 24),
              Text('BY MODEL', style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
              const SizedBox(height: 8),
              ...models.map((model) => _ModelCard(model: model, maxGens: models.first.totalGenerations, theme: theme)),
            ],
          ),
        );
      }),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final LlmModel model;
  final int maxGens;
  final ThemeData theme;
  const _ModelCard({required this.model, required this.maxGens, required this.theme});

  @override
  Widget build(BuildContext context) {
    final fraction = maxGens > 0 ? model.totalGenerations / maxGens : 0.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${model.totalGenerations} calls',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ModelStat(label: 'Avg Latency', value: '${model.avgLatency.toStringAsFixed(0)}ms'),
                const SizedBox(width: 16),
                _ModelStat(label: 'Input', value: _fmtTokens(model.inputTokens)),
                const SizedBox(width: 16),
                _ModelStat(label: 'Output', value: _fmtTokens(model.outputTokens)),
                const Spacer(),
                if (model.totalCost > 0)
                  Text(
                    '\$${model.totalCost.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ModelStat extends StatelessWidget {
  final String label;
  final String value;
  const _ModelStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }
}
