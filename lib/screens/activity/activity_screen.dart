import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../models/column_spec.dart';
import '../../models/event_item.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
    _loadColumns();
  }

  Future<void> _loadEvents() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    providers.eventsState.fetchEvents(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
    );

    // Load property definitions in background
    providers.eventsState.loadPropertyDefinitions(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
    );
  }

  Future<void> _loadColumns() async {
    final providers = AppProviders.of(context);
    await providers.eventsState.loadSavedColumns(providers.storage);
  }

  void _showColumnConfig() {
    final providers = AppProviders.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ColumnConfigSheet(
        eventsState: providers.eventsState,
        onSave: () => providers.eventsState.saveColumns(providers.storage),
      ),
    );
  }

  void _showEventDetail(EventItem event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EventDetailSheet(event: event),
    );
  }

  String _extractColumnValue(EventItem event, ColumnSpec column) {
    if (column.kind == ColumnKind.builtin) {
      switch (column.builtinId) {
        case BuiltinColumnId.event:
          return event.event;
        case BuiltinColumnId.distinctId:
          return event.distinctId;
        case BuiltinColumnId.timestamp:
          return event.timeAgo;
        case BuiltinColumnId.url:
          return event.getProperty('\$current_url') ?? '';
        case BuiltinColumnId.browser:
          return event.getProperty('\$browser') ?? '';
        case BuiltinColumnId.os:
          return event.getProperty('\$os') ?? '';
        case BuiltinColumnId.device:
          return event.getProperty('\$device_type') ?? '';
        default:
          return '';
      }
    }
    return event.getProperty(column.id) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).eventsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_column_outlined),
            onPressed: _showColumnConfig,
            tooltip: 'Configure columns',
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context, _) {
          if (state.isLoading.value && state.events.value.isEmpty) {
            return const ShimmerList();
          }
          if (state.error.value != null && state.events.value.isEmpty) {
            return ErrorView(error: state.error.value!, onRetry: _loadEvents);
          }

          final events = state.events.value;
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icons.bolt_outlined,
              title: 'No events yet',
              message: 'Events will appear here as they are captured',
            );
          }

          final columns = state.visibleColumns.value;

          return RefreshIndicator(
            onRefresh: _loadEvents,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventCard(
                  event: event,
                  columns: columns,
                  extractValue: _extractColumnValue,
                  onTap: () => _showEventDetail(event),
                  theme: theme,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventItem event;
  final List<ColumnSpec> columns;
  final String Function(EventItem, ColumnSpec) extractValue;
  final VoidCallback onTap;
  final ThemeData theme;

  const _EventCard({
    required this.event,
    required this.columns,
    required this.extractValue,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final column in columns)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          column.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          extractValue(event, column),
                          style: column.builtinId == BuiltinColumnId.event
                              ? theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )
                              : theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Column Config Bottom Sheet --

class _ColumnConfigSheet extends StatefulWidget {
  final dynamic eventsState; // EventsState
  final VoidCallback onSave;

  const _ColumnConfigSheet({required this.eventsState, required this.onSave});

  @override
  State<_ColumnConfigSheet> createState() => _ColumnConfigSheetState();
}

class _ColumnConfigSheetState extends State<_ColumnConfigSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.eventsState;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return SignalBuilder(
          builder: (context, _) {
            final columns = state.visibleColumns.value as List<ColumnSpec>;
            final available = ColumnSpec.allBuiltinColumns
                .where((c) => !columns.any((v) => v.id == c.id))
                .toList();

            return Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Columns', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          widget.onSave();
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text('VISIBLE', style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        )),
                      ),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: columns.length,
                        onReorder: (oldIndex, newIndex) {
                          state.reorderColumns(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final col = columns[index];
                          return ListTile(
                            key: ValueKey(col.id),
                            leading: const Icon(Icons.drag_handle, size: 20),
                            title: Text(col.label),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () => state.removeColumn(col.id),
                            ),
                            dense: true,
                          );
                        },
                      ),
                      if (available.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text('AVAILABLE', style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          )),
                        ),
                        ...available.map((col) => ListTile(
                              leading: const Icon(Icons.add_circle_outline, size: 20),
                              title: Text(col.label),
                              dense: true,
                              onTap: () => state.addColumn(col),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// -- Event Detail Bottom Sheet --

class _EventDetailSheet extends StatelessWidget {
  final EventItem event;

  const _EventDetailSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedKeys = event.properties.keys.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      event.event,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    event.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                event.distinctId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final key = sortedKeys[index];
                  final value = event.properties[key]?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 140,
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
                            value,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
