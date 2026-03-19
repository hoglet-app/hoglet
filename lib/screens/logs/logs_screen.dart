import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../models/log_entry.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.logsState.fetchLogs(
      p.client, c.host, c.projectId, c.apiKey,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).logsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchController.clear(); _load(); },
                      )
                    : null,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          // Level filter chips
          SignalBuilder(builder: (context, _) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  for (final level in ['debug', 'log', 'info', 'warn', 'error'])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _LevelChip(
                        level: level,
                        selected: state.selectedLevels.value.contains(level),
                        onTap: () {
                          state.toggleLevel(level);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
          // Logs list
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoading.value && state.logs.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.logs.value.isEmpty) {
                return ErrorView(error: state.error.value!, onRetry: _load);
              }
              if (state.logs.value.isEmpty) {
                return const EmptyState(icon: Icons.article_outlined, title: 'No logs found');
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: state.logs.value.length,
                  itemBuilder: (context, i) => _LogEntryRow(
                    entry: state.logs.value[i],
                    theme: theme,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  final bool selected;
  final VoidCallback onTap;
  const _LevelChip({required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(level);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(
          level.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? color : Colors.grey,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _LogEntryRow extends StatelessWidget {
  final LogEntry entry;
  final ThemeData theme;
  const _LogEntryRow({required this.entry, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(entry.level.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: entry.isError
            ? Colors.red.withValues(alpha: 0.04)
            : entry.isWarn
                ? Colors.orange.withValues(alpha: 0.03)
                : Colors.transparent,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              entry.timeStr,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(
              entry.level.length > 5 ? entry.level.substring(0, 5) : entry.level,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.message,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

Color _levelColor(String level) {
  switch (level) {
    case 'error':
      return Colors.red;
    case 'warn':
    case 'warning':
      return Colors.orange;
    case 'info':
      return Colors.blue;
    case 'debug':
      return Colors.grey;
    default:
      return Colors.teal;
  }
}
