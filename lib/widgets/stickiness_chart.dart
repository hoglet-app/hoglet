import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/insight.dart';
import 'breakdown_legend.dart';

class StickinessChart extends StatelessWidget {
  final InsightResult result;
  final double height;

  const StickinessChart({super.key, required this.result, this.height = 240});

  @override
  Widget build(BuildContext context) {
    final series = result.series;
    if (series.isEmpty || series.first.values.isEmpty) {
      return SizedBox(height: height, child: const Center(child: Text('No data')));
    }

    final s = series.first;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: BarChart(
          BarChartData(
            barGroups: List.generate(s.values.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: s.values[i],
                    color: getSeriesColor(0),
                    width: s.values.length > 20 ? 8 : 16,
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
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= s.labels.length) return const SizedBox.shrink();
                    return Text(s.labels[idx], style: const TextStyle(fontSize: 9, color: Colors.grey));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
