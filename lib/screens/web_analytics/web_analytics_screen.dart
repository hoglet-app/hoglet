import 'package:fl_chart/fl_chart.dart';
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

              // Daily visitors chart
              if (state.dailyVisitors.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                _DailyVisitorsChart(data: state.dailyVisitors.value, theme: theme),
              ],

              // Referrer bar chart
              if (state.topReferrers.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                _ReferrerBarChart(data: state.topReferrers.value, theme: theme),
              ],

              // Top Pages
              const SizedBox(height: 24),
              _SectionTable(title: 'TOP PAGES', icon: Icons.description, rows: state.topPages.value, nameLabel: 'Page', valueLabel: 'Views', theme: theme),

              // Browsers & Devices side by side
              if (state.topBrowsers.value.isNotEmpty || state.topDevices.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.topBrowsers.value.isNotEmpty)
                      Expanded(child: _MiniBreakdown(title: 'BROWSERS', icon: Icons.web, rows: state.topBrowsers.value, theme: theme)),
                    if (state.topBrowsers.value.isNotEmpty && state.topDevices.value.isNotEmpty)
                      const SizedBox(width: 12),
                    if (state.topDevices.value.isNotEmpty)
                      Expanded(child: _MiniBreakdown(title: 'DEVICES', icon: Icons.devices, rows: state.topDevices.value, theme: theme)),
                  ],
                ),
              ],
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

// -- Daily Visitors Line Chart --

class _DailyVisitorsChart extends StatelessWidget {
  final List<List<dynamic>> data;
  final ThemeData theme;
  const _DailyVisitorsChart({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final visitors = row.length > 1 ? (row[1] as num?)?.toDouble() ?? 0 : 0.0;
      spots.add(FlSpot(i.toDouble(), visitors));
      final dateStr = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
      labels.add(_shortDate(dateStr));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text('DAILY VISITORS', style: theme.textTheme.labelSmall?.copyWith(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 160,
              child: LineChart(LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    color: theme.colorScheme.primary,
                    barWidth: 2.5,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    dotData: FlDotData(show: spots.length <= 10),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: theme.colorScheme.onSurface.withValues(alpha: 0.06), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(_fmtNum(v.toInt()), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[i], style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                      );
                    },
                  )),
                ),
                borderData: FlBorderData(show: false),
              )),
            ),
          ),
        ),
      ],
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]}';
  }

  String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// -- Referrer Pie Chart --

const _pieColors = [
  Color(0xFF4C6EF5), // blue
  Color(0xFF12B886), // teal
  Color(0xFFF59F00), // yellow
  Color(0xFFFA5252), // red
  Color(0xFF7950F2), // violet
  Color(0xFFFF922B), // orange
  Color(0xFF20C997), // cyan
  Color(0xFFE64980), // pink
  Color(0xFF5C7CFA), // indigo
  Color(0xFF82C91E), // lime
];

class _ReferrerBarChart extends StatelessWidget {
  final List<List<dynamic>> data;
  final ThemeData theme;
  const _ReferrerBarChart({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, row) => sum + ((row.length > 1 ? row[1] as num? : 0)?.toDouble() ?? 0));

    final sections = data.asMap().entries.map((entry) {
      final row = entry.value;
      final val = row.length > 1 ? (row[1] as num?)?.toDouble() ?? 0 : 0.0;
      final color = _pieColors[entry.key % _pieColors.length];
      return PieChartSectionData(
        value: val,
        color: color,
        radius: 48,
        title: total > 0 ? '${(val / total * 100).toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text('REFERRING DOMAINS', style: theme.textTheme.labelSmall?.copyWith(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pie chart
                SizedBox(
                  height: 180,
                  child: PieChart(PieChartData(
                    sections: sections,
                    centerSpaceRadius: 32,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  )),
                ),
                const SizedBox(height: 16),
                // Legend
                ...data.asMap().entries.map((entry) {
                  final row = entry.value;
                  final name = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
                  final val = row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0;
                  final pct = total > 0 ? (val / total * 100).toStringAsFixed(1) : '0';
                  final color = _pieColors[entry.key % _pieColors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name.isEmpty ? '(direct / none)' : name,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          child: Text(
                            _fmtNum(val),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: color),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// -- Mini Breakdown (browsers/devices) --

class _MiniBreakdown extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<List<dynamic>> rows;
  final ThemeData theme;
  const _MiniBreakdown({required this.title, required this.icon, required this.rows, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (sum, r) => sum + ((r.length > 1 ? r[1] as num? : 0)?.toInt() ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: rows.take(5).map((row) {
                final name = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
                final val = row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0;
                final pct = total > 0 ? (val / total * 100).toStringAsFixed(0) : '0';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(name.isEmpty ? 'Other' : name, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('$pct%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// -- Summary Metric Card --

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

// -- Section Table (for top pages) --

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
        ? (rows.first[1] as num?)?.toDouble() ?? 1 : 1.0;

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
              ...rows.map((row) {
                final name = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
                final val = row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0;
                final fraction = maxVal > 0 ? val / maxVal : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(name.isEmpty ? '/' : name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(_formatNum(val), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
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
