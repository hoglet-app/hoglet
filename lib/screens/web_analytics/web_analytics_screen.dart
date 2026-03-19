import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class WebAnalyticsScreen extends StatefulWidget {
  const WebAnalyticsScreen({super.key});
  @override State<WebAnalyticsScreen> createState() => _WebAnalyticsScreenState();
}

class _WebAnalyticsScreenState extends State<WebAnalyticsScreen> {
  @override void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    p.webAnalyticsState.fetchWebAnalytics(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).webAnalyticsState;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Web Analytics'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.data.value == null) return const ShimmerList(itemCount: 3);
        if (state.error.value != null && state.data.value == null) return ErrorView(error: state.error.value!, onRetry: _load);
        final data = state.data.value ?? {};
        return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Last 7 Days', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(children: [
            _MetricCard(label: 'Visitors', value: _format(data['visitors']), icon: Icons.person, theme: theme),
            const SizedBox(width: 12),
            _MetricCard(label: 'Pageviews', value: _format(data['pageviews']), icon: Icons.pageview, theme: theme),
            const SizedBox(width: 12),
            _MetricCard(label: 'Sessions', value: _format(data['sessions']), icon: Icons.timer, theme: theme),
          ]),
        ]));
      }),
    );
  }

  String _format(dynamic v) {
    if (v == null) return '—';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
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
    return Expanded(child: Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(16),
      child: Column(children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ]),
    )));
  }
}
