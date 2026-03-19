import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/insight.dart';
import 'breakdown_legend.dart';
import 'lifecycle_chart.dart';
import 'paths_chart.dart';
import 'retention_table.dart';
import 'stickiness_chart.dart';

class ChartRenderer extends StatelessWidget {
  final Insight insight;
  final double height;

  const ChartRenderer({
    super.key,
    required this.insight,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (insight.result == null) {
      return _UnsupportedChart(insight: insight, height: height);
    }

    switch (insight.displayType) {
      case InsightDisplayType.trends:
        return _TrendsChart(result: insight.result!, height: height);
      case InsightDisplayType.funnels:
        return _FunnelsChart(result: insight.result!, height: height);
      case InsightDisplayType.number:
        return _NumberChart(result: insight.result!, height: height);
      case InsightDisplayType.retention:
        return RetentionTable(resultData: insight.raw['result'], height: height);
      case InsightDisplayType.lifecycle:
        return LifecycleChart(result: insight.result!, height: height);
      case InsightDisplayType.stickiness:
        return StickinessChart(result: insight.result!, height: height);
      case InsightDisplayType.paths:
        return PathsChart(resultData: insight.raw['result'], height: height);
      default:
        return _UnsupportedChart(insight: insight, height: height);
    }
  }
}

// -- Trends Chart (multi-series line/bar) --

class _TrendsChart extends StatelessWidget {
  final InsightResult result;
  final double height;

  const _TrendsChart({required this.result, required this.height});

  @override
  Widget build(BuildContext context) {
    final series = result.series;
    if (series.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('No data')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: LineChart(_buildLineData(series)),
          ),
        ),
        BreakdownLegend(series: series),
      ],
    );
  }

  LineChartData _buildLineData(List<InsightSeries> series) {
    final lines = <LineChartBarData>[];

    for (final s in series) {
      final spots = <FlSpot>[];
      for (var i = 0; i < s.values.length; i++) {
        spots.add(FlSpot(i.toDouble(), s.values[i]));
      }
      lines.add(LineChartBarData(
        spots: spots,
        color: getSeriesColor(s.colorIndex),
        barWidth: 2.5,
        dotData: FlDotData(show: s.values.length <= 12),
        isCurved: true,
        curveSmoothness: 0.2,
        belowBarData: series.length == 1
            ? BarAreaData(
                show: true,
                color: getSeriesColor(s.colorIndex).withValues(alpha: 0.08),
              )
            : null,
      ));
    }

    // Build label references from the first series
    final labels = series.first.labels;

    return LineChartData(
      lineBarsData: lines,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.15),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) => Text(
              _formatNumber(value),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _labelInterval(labels.length),
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _shortenLabel(labels[idx]),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final s = series[spot.barIndex];
              return LineTooltipItem(
                '${s.label}\n${_formatNumber(spot.y)}',
                TextStyle(
                  color: getSeriesColor(s.colorIndex),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  double _labelInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 7;
    return (count / 5).ceilToDouble();
  }
}

// -- Funnels Chart (horizontal bars) --

class _FunnelsChart extends StatelessWidget {
  final InsightResult result;
  final double height;

  const _FunnelsChart({required this.result, required this.height});

  @override
  Widget build(BuildContext context) {
    final steps = result.funnelSteps;
    if (steps == null || steps.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('No data')));
    }

    final theme = Theme.of(context);
    final maxCount = steps.map((s) => s.count).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _FunnelStepRow(
              step: steps[i],
              maxCount: maxCount,
              isFirst: i == 0,
              theme: theme,
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                child: Text(
                  '↓ ${steps[i + 1].conversionRate.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _conversionColor(steps[i + 1].conversionRate),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Color _conversionColor(double rate) {
    if (rate >= 70) return Colors.green;
    if (rate >= 40) return Colors.orange;
    return Colors.red;
  }
}

class _FunnelStepRow extends StatelessWidget {
  final FunnelStep step;
  final int maxCount;
  final bool isFirst;
  final ThemeData theme;

  const _FunnelStepRow({
    required this.step,
    required this.maxCount,
    required this.isFirst,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? step.count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                step.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${_formatNumber(step.count.toDouble())} (${step.conversionRate.toStringAsFixed(1)}%)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 24,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(
              isFirst
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.4 + fraction * 0.6),
            ),
          ),
        ),
      ],
    );
  }
}

// -- Number Chart --

class _NumberChart extends StatelessWidget {
  final InsightResult result;
  final double height;

  const _NumberChart({required this.result, required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = result.numberValue;

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value != null ? _formatNumber(value) : '—',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            if (result.previousValue != null && value != null) ...[
              const SizedBox(height: 8),
              _DeltaBadge(current: value, previous: result.previousValue!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double current;
  final double previous;

  const _DeltaBadge({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    if (previous == 0) return const SizedBox.shrink();

    final delta = ((current - previous) / previous * 100);
    final isPositive = delta >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '${delta.abs().toStringAsFixed(1)}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

// -- Unsupported Chart --

class _UnsupportedChart extends StatelessWidget {
  final Insight insight;
  final double height;

  const _UnsupportedChart({required this.insight, required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeName = insight.displayType.name;

    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),
            Text(
              typeName[0].toUpperCase() + typeName.substring(1),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'View on PostHog',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Utilities --

String _formatNumber(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String _shortenLabel(String label) {
  // Convert "1-Jan-2024" to "1 Jan" or similar short form
  if (label.length > 6) {
    final parts = label.split('-');
    if (parts.length >= 2) return '${parts[0]} ${parts[1]}';
    return label.substring(0, 6);
  }
  return label;
}
