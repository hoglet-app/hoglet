import 'package:flutter/material.dart';

class RetentionTable extends StatelessWidget {
  final dynamic resultData;
  final double height;

  const RetentionTable({super.key, required this.resultData, this.height = 300});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _parseRetentionData();
    if (rows.isEmpty) return SizedBox(height: height, child: const Center(child: Text('No retention data')));

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(56),
              border: TableBorder.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              children: [
                // Header row
                TableRow(
                  children: [
                    _headerCell('Cohort', theme),
                    _headerCell('Size', theme),
                    for (var i = 0; i < (rows.isEmpty ? 0 : rows.first.percentages.length); i++)
                      _headerCell('Day $i', theme),
                  ],
                ),
                // Data rows
                for (final row in rows)
                  TableRow(
                    children: [
                      _dataCell(row.label, theme),
                      _dataCell(row.size.toString(), theme),
                      for (final pct in row.percentages)
                        _percentCell(pct, theme),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_RetentionRow> _parseRetentionData() {
    if (resultData is! List) return [];
    final data = resultData as List;
    final rows = <_RetentionRow>[];

    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final label = item['label']?.toString() ?? item['date']?.toString() ?? '';
        final values = item['values'] as List? ?? [];
        final size = values.isNotEmpty && values.first is Map ? (values.first['count'] as num?)?.toInt() ?? 0 : 0;
        final percentages = <double>[];
        for (final v in values) {
          if (v is Map<String, dynamic>) {
            final count = (v['count'] as num?)?.toInt() ?? 0;
            percentages.add(size > 0 ? (count / size * 100) : 0);
          }
        }
        rows.add(_RetentionRow(label: label, size: size, percentages: percentages));
      }
    }
    return rows;
  }
}

class _RetentionRow {
  final String label;
  final int size;
  final List<double> percentages;
  _RetentionRow({required this.label, required this.size, required this.percentages});
}

Widget _headerCell(String text, ThemeData theme) => Padding(
  padding: const EdgeInsets.all(6),
  child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.center),
);

Widget _dataCell(String text, ThemeData theme) => Padding(
  padding: const EdgeInsets.all(6),
  child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
);

Widget _percentCell(double pct, ThemeData theme) {
  final opacity = (pct / 100).clamp(0.0, 1.0);
  return Container(
    padding: const EdgeInsets.all(6),
    color: theme.colorScheme.primary.withValues(alpha: opacity * 0.4),
    child: Text('${pct.toStringAsFixed(0)}%', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), textAlign: TextAlign.center),
  );
}
