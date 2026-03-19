import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class WebAnalyticsScreen extends StatefulWidget {
  const WebAnalyticsScreen({super.key});
  @override
  State<WebAnalyticsScreen> createState() => _WebAnalyticsScreenState();
}

class _WebAnalyticsScreenState extends State<WebAnalyticsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    await p.webAnalyticsState.fetchWebAnalytics(p.client, c.host, c.projectId, c.apiKey);
    p.webAnalyticsState.fetchDetails(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).webAnalyticsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Web Analytics'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.data.value == null) return const ShimmerList(itemCount: 3);
        if (state.error.value != null && state.data.value == null) {
          return ErrorView(error: state.error.value!, onRetry: _load);
        }
        final data = state.data.value ?? {};

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary metrics
              Text('LAST 7 DAYS', style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MetricCard(label: 'Visitors', value: _format(data['visitors']), icon: Icons.person, theme: theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricCard(label: 'Pageviews', value: _format(data['pageviews']), icon: Icons.pageview, theme: theme)),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricCard(label: 'Sessions', value: _format(data['sessions']), icon: Icons.timer, theme: theme)),
                ],
              ),

              // Top Pages
              const SizedBox(height: 24),
              _SectionTable(
                title: 'TOP PAGES',
                icon: Icons.description,
                rows: state.topPages.value,
                nameLabel: 'Page',
                valueLabel: 'Views',
                theme: theme,
              ),

              // Top Referrers
              const SizedBox(height: 24),
              _SectionTable(
                title: 'TOP REFERRERS',
                icon: Icons.link,
                rows: state.topReferrers.value,
                nameLabel: 'Referrer',
                valueLabel: 'Views',
                theme: theme,
              ),

              // Top Browsers
              const SizedBox(height: 24),
              _SectionTable(
                title: 'BROWSERS',
                icon: Icons.web,
                rows: state.topBrowsers.value,
                nameLabel: 'Browser',
                valueLabel: 'Views',
                theme: theme,
              ),
            ],
          ),
        );
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
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SectionTable extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<List<dynamic>> rows;
  final String nameLabel;
  final String valueLabel;
  final ThemeData theme;

  const _SectionTable({
    required this.title,
    required this.icon,
    required this.rows,
    required this.nameLabel,
    required this.valueLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final maxVal = rows.isNotEmpty && rows.first.length > 1
        ? (rows.first[1] as num?)?.toDouble() ?? 1
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(nameLabel, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                    Text(valueLabel, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...rows.asMap().entries.map((entry) {
                final row = entry.value;
                final name = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
                final val = row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0;
                final fraction = maxVal > 0 ? val / maxVal : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? '(direct)' : name,
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatNum(val),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 4,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary.withValues(alpha: 0.3 + fraction * 0.7)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
