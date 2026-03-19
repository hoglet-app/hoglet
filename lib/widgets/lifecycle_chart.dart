import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/insight.dart';
import 'breakdown_legend.dart';

class LifecycleChart extends StatelessWidget {
  final InsightResult result;
  final double height;

  const LifecycleChart({super.key, required this.result, this.height = 240});

  static const _lifecycleColors = {
    'new': Color(0xFF1D4AFF),
    'returning': Color(0xFF4BC0C0),
    'resurrecting': Color(0xFFFFCD56),
    'dormant': Color(0xFFFF6384),
  };

  @override
  Widget build(BuildContext context) {
    final series = result.series;
    if (series.isEmpty) return SizedBox(height: height, child: const Center(child: Text('No data')));

    final maxLen = series.map((s) => s.values.length).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: BarChart(
              BarChartData(
                barGroups: List.generate(maxLen, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _stackedTotal(series, i),
                        rodStackItems: _buildStack(series, i),
                        width: maxLen > 20 ? 8 : 16,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)))),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            children: series.map((s) {
              final label = s.label.toLowerCase();
              final color = _lifecycleColors.entries.firstWhere((e) => label.contains(e.key), orElse: () => MapEntry('', getSeriesColor(s.colorIndex))).value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(s.label, style: Theme.of(context).textTheme.bodySmall),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  double _stackedTotal(List<InsightSeries> series, int idx) {
    double total = 0;
    for (final s in series) {
      if (idx < s.values.length) total += s.values[idx].abs();
    }
    return total;
  }

  List<BarChartRodStackItem> _buildStack(List<InsightSeries> series, int idx) {
    final items = <BarChartRodStackItem>[];
    double fromY = 0;
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      if (idx < s.values.length) {
        final val = s.values[idx].abs();
        final label = s.label.toLowerCase();
        final color = _lifecycleColors.entries.firstWhere((e) => label.contains(e.key), orElse: () => MapEntry('', getSeriesColor(i))).value;
        items.add(BarChartRodStackItem(fromY, fromY + val, color));
        fromY += val;
      }
    }
    return items;
  }
}
