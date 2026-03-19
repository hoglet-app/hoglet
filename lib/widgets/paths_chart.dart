import 'package:flutter/material.dart';

/// Displays a Paths insight as a simplified flow/sankey diagram.
/// PostHog Paths show user journeys between events/pages.
class PathsChart extends StatelessWidget {
  final dynamic resultData;
  final double height;

  const PathsChart({super.key, required this.resultData, this.height = 300});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paths = _parsePaths();

    if (paths.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No path data')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Paths',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...paths.take(15).map((path) => _PathRow(path: path, maxCount: paths.first.count, theme: theme)),
        ],
      ),
    );
  }

  List<_PathEntry> _parsePaths() {
    final entries = <_PathEntry>[];

    if (resultData is List) {
      for (final item in resultData as List) {
        if (item is Map<String, dynamic>) {
          // Paths result format: [{source: "...", target: "...", value: N}, ...]
          final source = item['source_event']?.toString() ?? item['source']?.toString() ?? '';
          final target = item['target_event']?.toString() ?? item['target']?.toString() ?? '';
          final value = (item['value'] as num?)?.toInt() ?? (item['event_count'] as num?)?.toInt() ?? 0;
          if (source.isNotEmpty || target.isNotEmpty) {
            entries.add(_PathEntry(source: source, target: target, count: value));
          }
        }
      }
    }

    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries;
  }
}

class _PathEntry {
  final String source;
  final String target;
  final int count;

  _PathEntry({required this.source, required this.target, required this.count});
}

class _PathRow extends StatelessWidget {
  final _PathEntry path;
  final int maxCount;
  final ThemeData theme;

  const _PathRow({required this.path, required this.maxCount, required this.theme});

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount > 0 ? path.count / maxCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: _shortenPath(path.source),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    TextSpan(
                      text: '  →  ',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                    TextSpan(
                      text: _shortenPath(path.target),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${path.count}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary.withValues(alpha: 0.3 + fraction * 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  String _shortenPath(String path) {
    // Shorten URLs and long event names
    if (path.startsWith('/')) {
      return path.length > 30 ? '${path.substring(0, 27)}...' : path;
    }
    if (path.startsWith('\$')) return path.replaceFirst('\$', '');
    return path.length > 25 ? '${path.substring(0, 22)}...' : path;
  }
}
