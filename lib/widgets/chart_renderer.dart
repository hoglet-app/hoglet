import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/insight.dart';

const _seriesColors = [
  Color(0xFFF15A24),
  Color(0xFF1D4AFF),
  Color(0xFF621DA6),
  Color(0xFF42827E),
  Color(0xFFCE0E29),
];

class ChartRenderer extends StatelessWidget {
  const ChartRenderer({super.key, required this.insight, this.compact = false});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!insight.isSupportedChart) {
      return _UnsupportedChart(type: insight.displayType);
    }
    switch (insight.displayType) {
      case 'TRENDS':
        return _TrendsChart(insight: insight, compact: compact);
      case 'FUNNELS':
        return _FunnelsChart(insight: insight, compact: compact);
      case 'NUMBER':
        return _NumberChart(insight: insight);
      default:
        return _UnsupportedChart(type: insight.displayType);
    }
  }
}

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

/// Parses a TRENDS result into a list of color+spots pairs.
/// Each series is a map with a `data` list of numbers.
List<({Color color, List<FlSpot> spots})> _parseTrendsSeries(dynamic result) {
  if (result is! List || result.isEmpty) return [];

  final output = <({Color color, List<FlSpot> spots})>[];

  for (var i = 0; i < result.length; i++) {
    final series = result[i];
    if (series is! Map) continue;

    final rawData = series['data'];
    if (rawData is! List) continue;

    final spots = <FlSpot>[];
    for (var j = 0; j < rawData.length; j++) {
      final raw = rawData[j];
      final y = raw is num ? raw.toDouble() : null;
      if (y != null) {
        spots.add(FlSpot(j.toDouble(), y));
      }
    }

    final color = _seriesColors[i % _seriesColors.length];
    output.add((color: color, spots: spots));
  }

  return output;
}

/// Parses a FUNNELS result into a list of (name, conversionRate) pairs.
List<({String name, double value})> _parseFunnelsSteps(dynamic result) {
  if (result is! List || result.isEmpty) return [];

  // PostHog funnels result can be List<List> or List<Map>
  List<dynamic> steps;
  if (result.first is List) {
    steps = result.first as List;
  } else {
    steps = result;
  }

  final output = <({String name, double value})>[];
  for (final step in steps) {
    if (step is! Map) continue;
    final name = (step['name'] as String?) ?? '';
    final raw = step['conversion_rate'] ?? step['count'];
    final value = raw is num ? raw.toDouble() : 0.0;
    output.add((name: name, value: value));
  }
  return output;
}

/// Parses a NUMBER result and returns the display string.
String _parseNumberValue(dynamic result) {
  if (result is! List || result.isEmpty) return '—';
  final first = result.first;
  if (first is! Map) return '—';

  final raw = first['aggregated_value'] ?? first['count'];
  if (raw == null) return '—';

  final num value = raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
  // Format large numbers compactly
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(value == value.truncate() ? 0 : 2);
}

// ---------------------------------------------------------------------------
// _TrendsChart
// ---------------------------------------------------------------------------

class _TrendsChart extends StatelessWidget {
  const _TrendsChart({required this.insight, required this.compact});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final series = _parseTrendsSeries(insight.result);

    if (series.isEmpty) {
      return const _EmptyData();
    }

    final lineBarsData = series.map((s) {
      return LineChartBarData(
        spots: s.spots,
        isCurved: true,
        color: s.color,
        barWidth: compact ? 1.5 : 2,
        dotData: FlDotData(show: !compact),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    final titlesData = compact
        ? const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          )
        : const FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          );

    final gridData = compact
        ? const FlGridData(show: false)
        : const FlGridData();

    return LineChart(
      LineChartData(
        lineBarsData: lineBarsData,
        titlesData: titlesData,
        gridData: gridData,
        borderData: FlBorderData(show: !compact),
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FunnelsChart
// ---------------------------------------------------------------------------

class _FunnelsChart extends StatelessWidget {
  const _FunnelsChart({required this.insight, required this.compact});

  final Insight insight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final steps = _parseFunnelsSteps(insight.result);

    if (steps.isEmpty) {
      return const _EmptyData();
    }

    final barGroups = steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final color = _seriesColors[index % _seriesColors.length];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: step.value,
            color: color,
            width: compact ? 8 : 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    Widget getTitleWidget(double value, TitleMeta meta) {
      final index = value.toInt();
      if (index < 0 || index >= steps.length) return const SizedBox.shrink();
      final name = steps[index].name;
      final label = name.length > 8 ? '${name.substring(0, 7)}…' : name;
      return SideTitleWidget(
        meta: meta,
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, color: Color(0xFF6F6A63)),
        ),
      );
    }

    final titlesData = compact
        ? const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
          )
        : FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: getTitleWidget,
              ),
            ),
          );

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: titlesData,
        gridData: compact
            ? const FlGridData(show: false)
            : const FlGridData(),
        borderData: FlBorderData(show: !compact),
        barTouchData: BarTouchData(enabled: false),
        maxY: 100,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NumberChart
// ---------------------------------------------------------------------------

class _NumberChart extends StatelessWidget {
  const _NumberChart({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final value = _parseNumberValue(insight.result);

    return Center(
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1C1B19),
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _UnsupportedChart
// ---------------------------------------------------------------------------

class _UnsupportedChart extends StatelessWidget {
  const _UnsupportedChart({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconForType(type),
            size: 28,
            color: const Color(0xFF9E9890),
          ),
          const SizedBox(height: 6),
          Text(
            _labelForType(type),
            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9890)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'RETENTION':
        return Icons.grid_on;
      case 'LIFECYCLE':
        return Icons.auto_graph;
      case 'PATHS':
        return Icons.account_tree;
      case 'STICKINESS':
        return Icons.show_chart;
      default:
        return Icons.bar_chart;
    }
  }

  static String _labelForType(String type) {
    switch (type) {
      case 'RETENTION':
        return 'Retention';
      case 'LIFECYCLE':
        return 'Lifecycle';
      case 'PATHS':
        return 'Paths';
      case 'STICKINESS':
        return 'Stickiness';
      case 'UNKNOWN':
        return 'Chart';
      default:
        return type[0] + type.substring(1).toLowerCase();
    }
  }
}

// ---------------------------------------------------------------------------
// _EmptyData
// ---------------------------------------------------------------------------

class _EmptyData extends StatelessWidget {
  const _EmptyData();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No data',
        style: TextStyle(fontSize: 12, color: Color(0xFF9E9890)),
      ),
    );
  }
}
