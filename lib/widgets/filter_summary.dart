import 'package:flutter/material.dart';

import '../models/insight.dart';

class FilterSummary extends StatelessWidget {
  final Insight insight;

  const FilterSummary({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];

    // Extract breakdown info from filters or query
    final filters = insight.filters;
    if (filters != null) {
      final breakdown = filters['breakdown'];
      final breakdownType = filters['breakdown_type']?.toString();
      if (breakdown != null) {
        final label = breakdownType == 'person'
            ? 'Person: $breakdown'
            : 'Grouped by: $breakdown';
        chips.add(label);
      }

      final dateFrom = filters['date_from']?.toString();
      if (dateFrom != null) {
        chips.add(dateFrom);
      }
    }

    // Check query source for breakdowns
    final query = insight.query;
    if (query != null) {
      final source = query['source'] as Map<String, dynamic>? ?? query;
      final breakdownFilter = source['breakdownFilter'] as Map<String, dynamic>?;
      if (breakdownFilter != null) {
        final breakdowns = breakdownFilter['breakdowns'] as List?;
        if (breakdowns != null && breakdowns.isNotEmpty) {
          for (final b in breakdowns) {
            if (b is Map<String, dynamic>) {
              final prop = b['property']?.toString() ?? 'unknown';
              chips.add('Grouped by: $prop');
            }
          }
        }
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        children: chips.map((chip) {
          return Text(
            chip,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }
}
