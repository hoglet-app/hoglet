import 'package:flutter/material.dart';

import '../models/insight.dart';

const _seriesColors = [
  Color(0xFF1D4AFF), // blue
  Color(0xFFCD0F74), // pink
  Color(0xFF621DA6), // purple
  Color(0xFFFF6900), // orange
  Color(0xFF36A2EB), // light blue
  Color(0xFF4BC0C0), // teal
  Color(0xFFFFCD56), // yellow
  Color(0xFF9966FF), // violet
  Color(0xFFFF9F40), // light orange
  Color(0xFF00C49F), // green
];

Color getSeriesColor(int index) => _seriesColors[index % _seriesColors.length];

class BreakdownLegend extends StatelessWidget {
  final List<InsightSeries> series;

  const BreakdownLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: series.map((s) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: getSeriesColor(s.colorIndex),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  s.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
