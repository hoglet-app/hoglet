import 'package:flutter/material.dart';

class PropertyTable extends StatelessWidget {
  final Map<String, dynamic> properties;
  final int? maxRows;

  const PropertyTable({super.key, required this.properties, this.maxRows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = properties.keys.toList()..sort();
    final displayKeys = maxRows != null ? keys.take(maxRows!) : keys;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in displayKeys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    key,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatValue(properties[key]),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        if (maxRows != null && keys.length > maxRows!)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${keys.length - maxRows!} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map || value is List) return value.toString();
    return value.toString();
  }
}
