import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

const _chartColors = [
  Color(0xFF4C6EF5), Color(0xFF12B886), Color(0xFFF59F00),
  Color(0xFFFA5252), Color(0xFF7950F2), Color(0xFFFF922B),
  Color(0xFF20C997), Color(0xFFE64980), Color(0xFF5C7CFA),
  Color(0xFF82C91E),
];

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
        if (state.error.value != null && state.data.value == null) return ErrorView(error: state.error.value!, onRetry: _load);
        final data = state.data.value ?? {};

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // -- OVERVIEW --
              _SectionLabel('OVERVIEW — LAST 7 DAYS'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _MetricCard(label: 'Visitors', value: _fmt(data['visitors']), icon: Icons.person, theme: theme)),
                const SizedBox(width: 8),
                Expanded(child: _MetricCard(label: 'Pageviews', value: _fmt(data['pageviews']), icon: Icons.pageview, theme: theme)),
                const SizedBox(width: 8),
                Expanded(child: _MetricCard(label: 'Sessions', value: _fmt(data['sessions']), icon: Icons.timer, theme: theme)),
              ]),

              // -- GRAPH: Daily Visitors --
              if (state.dailyVisitors.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                _DailyChart(data: state.dailyVisitors.value, theme: theme),
              ],

              // -- SOURCES: Referring Domains (pie + table) --
              if (state.topReferrers.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SourcesTile(referrers: state.topReferrers.value, utmSources: state.topUTMSources.value, theme: theme),
              ],

              // -- PATHS: Top Pages --
              if (state.topPages.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                _DataTable3Col(title: 'TOP PAGES', icon: Icons.description, rows: state.topPages.value, col1: 'Page', col2: 'Views', col3: 'Visitors', theme: theme),
              ],

              // -- GEOGRAPHY --
              if (state.topCountries.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                _DataTable3Col(title: 'GEOGRAPHY', icon: Icons.public, rows: state.topCountries.value, col1: 'Country', col2: 'Visitors', col3: 'Views', theme: theme),
              ],

              // -- DEVICES --
              if (state.topBrowsers.value.isNotEmpty || state.topDevices.value.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (state.topBrowsers.value.isNotEmpty)
                    Expanded(child: _MiniBreakdown(title: 'BROWSERS', icon: Icons.web, rows: state.topBrowsers.value, theme: theme)),
                  if (state.topBrowsers.value.isNotEmpty && state.topDevices.value.isNotEmpty)
                    const SizedBox(width: 12),
                  if (state.topDevices.value.isNotEmpty)
                    Expanded(child: _MiniBreakdown(title: 'DEVICES', icon: Icons.devices, rows: state.topDevices.value, theme: theme)),
                ]),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// -- Section Label --
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 1.2, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
    ));
  }
}

// -- Metric Card --
class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final ThemeData theme;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
      ])),
    );
  }
}

// -- Daily Visitors Line Chart --
class _DailyChart extends StatelessWidget {
  final List<List<dynamic>> data;
  final ThemeData theme;
  const _DailyChart({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i].length > 1 ? (data[i][1] as num?)?.toDouble() : 0) ?? 0));
      labels.add(_shortDate(data[i].isNotEmpty ? data[i][0]?.toString() ?? '' : ''));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionLabel('UNIQUE VISITORS'),
      const SizedBox(height: 8),
      Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
        child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 16, 8), child: SizedBox(height: 160, child: LineChart(LineChartData(
          lineBarsData: [LineChartBarData(spots: spots, color: theme.colorScheme.primary, barWidth: 2.5, isCurved: true, curveSmoothness: 0.3, dotData: FlDotData(show: spots.length <= 10),
            belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.08)))],
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: theme.colorScheme.onSurface.withValues(alpha: 0.06), strokeWidth: 1)),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(_fmtN(v.toInt()), style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, _) { final i = v.toInt(); if (i < 0 || i >= labels.length) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))); })),
          ),
          borderData: FlBorderData(show: false),
        ))))),
    ]);
  }
  String _shortDate(String iso) { final dt = DateTime.tryParse(iso); if (dt == null) return iso; const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${dt.day} ${m[dt.month]}'; }
  String _fmtN(int n) { if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K'; return n.toString(); }
}

// -- Sources Tile: Pie chart + Referrer table + UTM table --
class _SourcesTile extends StatefulWidget {
  final List<List<dynamic>> referrers;
  final List<List<dynamic>> utmSources;
  final ThemeData theme;
  const _SourcesTile({required this.referrers, required this.utmSources, required this.theme});
  @override
  State<_SourcesTile> createState() => _SourcesTileState();
}

class _SourcesTileState extends State<_SourcesTile> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: widget.utmSources.isNotEmpty ? 2 : 1, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.link, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        const _SectionLabel('SOURCES'),
        const Spacer(),
        if (widget.utmSources.isNotEmpty)
          SizedBox(height: 28, child: TabBar(controller: _tab, isScrollable: true, tabAlignment: TabAlignment.start, labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [const Tab(text: 'Referring Domain'), const Tab(text: 'UTM Source')],
          )),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: _tileHeight,
        child: TabBarView(controller: _tab, children: [
          _ReferrerTab(data: widget.referrers, theme: theme),
          if (widget.utmSources.isNotEmpty)
            _ReferrerTab(data: widget.utmSources, theme: theme),
        ]),
      ),
    ]);
  }

  double get _tileHeight {
    final rows = widget.referrers.length;
    // pie 200 + legend rows + table header + data rows
    return 200.0 + (rows * 22.0) + 48.0 + (rows * 40.0) + 24;
  }
}

class _ReferrerTab extends StatelessWidget {
  final List<List<dynamic>> data;
  final ThemeData theme;
  const _ReferrerTab({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (s, r) => s + ((r.length > 1 ? r[1] as num? : 0)?.toDouble() ?? 0));
    final sections = data.asMap().entries.map((e) {
      final val = (e.value.length > 1 ? (e.value[1] as num?)?.toDouble() ?? 0.0 : 0.0);
      final pct = total > 0 ? (val / total * 100.0) : 0.0;
      return PieChartSectionData(value: val, color: _chartColors[e.key % _chartColors.length], radius: 40,
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '', titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), titlePositionPercentageOffset: 0.55);
    }).toList();

    return SingleChildScrollView(child: Column(children: [
      // Pie
      Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
        child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          SizedBox(height: 160, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 28, sectionsSpace: 2, borderData: FlBorderData(show: false)))),
          const SizedBox(height: 12),
          // Legend
          Wrap(spacing: 10, runSpacing: 4, alignment: WrapAlignment.center, children: data.asMap().entries.map((e) {
            final name = e.value.isNotEmpty ? e.value[0]?.toString() ?? '' : '';
            final val = (e.value.length > 1 ? (e.value[1] as num?)?.toDouble() ?? 0.0 : 0.0);
            final pct = total > 0 ? (val / total * 100).toStringAsFixed(0) : '0';
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: _chartColors[e.key % _chartColors.length], borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('${name.isEmpty ? '(direct)' : _trunc(name)} $pct%', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ]);
          }).toList()),
        ]))),
      const SizedBox(height: 12),
      // Data table
      Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
            Expanded(child: Text('Domain', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
            SizedBox(width: 60, child: Text('Visitors', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
            SizedBox(width: 60, child: Text('Views', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
          ])),
          const Divider(height: 1),
          ...data.asMap().entries.map((e) {
            final name = e.value.isNotEmpty ? e.value[0]?.toString() ?? '' : '';
            final visitors = e.value.length > 1 ? (e.value[1] as num?)?.toInt() ?? 0 : 0;
            final views = e.value.length > 2 ? (e.value[2] as num?)?.toInt() ?? 0 : 0;
            final color = _chartColors[e.key % _chartColors.length];
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
              Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              Expanded(child: Text(name.isEmpty ? '(direct)' : name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 60, child: Text('$visitors', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              SizedBox(width: 60, child: Text('$views', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
            ]));
          }),
          const SizedBox(height: 8),
        ])),
    ]));
  }

  String _trunc(String s) => s.length > 18 ? '${s.substring(0, 15)}...' : s;
}

// -- Data Table 3 columns (name, col2, col3) --
class _DataTable3Col extends StatelessWidget {
  final String title, col1, col2, col3;
  final IconData icon;
  final List<List<dynamic>> rows;
  final ThemeData theme;
  const _DataTable3Col({required this.title, required this.icon, required this.rows, required this.col1, required this.col2, required this.col3, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final maxVal = rows.isNotEmpty && rows.first.length > 1 ? (rows.first[1] as num?)?.toDouble() ?? 1 : 1.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        _SectionLabel(title),
      ]),
      const SizedBox(height: 8),
      Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Row(children: [
            Expanded(child: Text(col1, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
            SizedBox(width: 60, child: Text(col2, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
            SizedBox(width: 60, child: Text(col3, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
          ])),
          const Divider(height: 1),
          ...rows.map((row) {
            final name = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
            final v1 = row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0;
            final v2 = row.length > 2 ? (row[2] as num?)?.toInt() ?? 0 : 0;
            final fraction = maxVal > 0 ? v1 / maxVal : 0.0;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Column(children: [
              Row(children: [
                Expanded(child: Text(name.isEmpty ? '/' : name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                SizedBox(width: 60, child: Text('$v1', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary), textAlign: TextAlign.right)),
                SizedBox(width: 60, child: Text('$v2', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)), textAlign: TextAlign.right)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: fraction, minHeight: 3, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary.withValues(alpha: 0.3 + fraction * 0.7)))),
            ]));
          }),
          const SizedBox(height: 8),
        ])),
    ]);
  }
}

// -- Mini Breakdown --
class _MiniBreakdown extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<List<dynamic>> rows;
  final ThemeData theme;
  const _MiniBreakdown({required this.title, required this.icon, required this.rows, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (s, r) => s + ((r.length > 1 ? r[1] as num? : 0)?.toInt() ?? 0));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        const SizedBox(width: 4),
        _SectionLabel(title),
      ]),
      const SizedBox(height: 8),
      Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(
          children: rows.take(5).map((row) {
            final name = row.isNotEmpty ? row[0]?.toString() ?? '' : '';
            final val = row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0;
            final pct = total > 0 ? (val / total * 100).toStringAsFixed(0) : '0';
            return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
              Expanded(child: Text(name.isEmpty ? 'Other' : name, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('$pct%', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
            ]));
          }).toList(),
        ))),
    ]);
  }
}
