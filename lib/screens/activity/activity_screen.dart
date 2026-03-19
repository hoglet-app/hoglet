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
  final _searchController = TextEditingController();
  String? _eventFilter;
  bool _showSearch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
    _loadColumns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: _showSearch
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Filter by event name...',
                  border: InputBorder.none,
                ),
                autofocus: true,
                onChanged: (v) => setState(() => _eventFilter = v.isEmpty ? null : v),
              )
            : const Text('Activity'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _eventFilter = null;
                }
              });
            },
            tooltip: _showSearch ? 'Close search' : 'Search events',
          ),
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

          var events = state.events.value;
          if (_eventFilter != null && _eventFilter!.isNotEmpty) {
            final filter = _eventFilter!.toLowerCase();
            events = events.where((e) => e.event.toLowerCase().contains(filter)).toList();
          }
          if (events.isEmpty && state.events.value.isNotEmpty && _eventFilter != null) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No matching events',
              message: 'Try a different search term',
            );
          }
          if (events.isEmpty) {
            return const EmptyState(
              icon: Icons.bolt_outlined,
              title: 'No events yet',
              message: 'Events will appear here as they are captured',
            );
          }

          final columns = state.visibleColumns.value;

          // Add 1 for the "load more" footer
          final showLoadMore = state.hasMore.value && _eventFilter == null;
          final itemCount = events.length + (showLoadMore ? 1 : 0);

          return RefreshIndicator(
            onRefresh: _loadEvents,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index >= events.length) {
                  // Load more footer
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SignalBuilder(builder: (context, _) {
                        if (state.isLoadingMore.value) {
                          return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        return TextButton(
                          onPressed: () async {
                            final p = AppProviders.of(context);
                            final c = await p.storage.readCredentials();
                            if (c != null) {
                              p.eventsState.loadMoreEvents(p.client, c.host, c.projectId, c.apiKey);
                            }
                          },
                          child: const Text('Load more events'),
                        );
                      }),
                    ),
                  );
                }
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
    final url = event.getProperty('\$current_url') ?? event.getProperty('\$screen_name');
    final browser = event.getProperty('\$browser');
    final os = event.getProperty('\$os');
    final city = event.getProperty('\$geoip_city_name');
    final country = event.getProperty('\$geoip_country_code');
    final isPageview = event.event == '\$pageview';
    final isCustom = !event.event.startsWith('\$');

    return Card(
      elevation: 0,
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
              // Row 1: Event name + timestamp
              Row(
                children: [
                  Icon(
                    isPageview ? Icons.pageview
                        : isCustom ? Icons.bolt
                        : Icons.analytics,
                    size: 16,
                    color: isCustom
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatEventName(event.event),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    event.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),

              // Row 2: Person
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.distinctId,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Row 3: URL (if present)
              if (url != null && url.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          url,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Row 4: Device metadata chips
              if (browser != null || os != null || city != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (os != null) _MetaChip(icon: Icons.devices, label: os, theme: theme),
                      if (browser != null) _MetaChip(icon: Icons.web, label: browser, theme: theme),
                      if (city != null || country != null)
                        _MetaChip(
                          icon: Icons.location_on,
                          label: [city, country].where((s) => s != null).join(', '),
                          theme: theme,
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

  String _formatEventName(String name) {
    if (name.startsWith('\$')) {
      // Convert $pageview -> Pageview, $autocapture -> Autocapture
      return name.substring(1).replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
    return name;
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  const _MetaChip({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
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
