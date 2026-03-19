import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../di/providers.dart';
import '../models/column_spec.dart';
import '../models/event_item.dart';
import '../services/storage_service.dart';
import '../state/events_state.dart';
import '../widgets/loading_states.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  EventsState? _eventsState;
  StorageService? _storage;
  bool _initialized = false;

  bool _missingCredentials = false;

  // UI-only state for the column config dialog
  String _columnSearch = '';
  ColumnCategory _selectedCategory = ColumnCategory.event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _eventsState = AppProviders.of(context).eventsState;
      _storage = AppProviders.of(context).storage;
      _init();
    }
  }

  Future<void> _init() async {
    final eventsState = _eventsState!;
    final storage = _storage!;

    eventsState.registerBuiltinColumns();
    await eventsState.loadVisibleColumns();

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
      if (mounted) {
        setState(() => _missingCredentials = true);
      }
      return;
    }

    if (mounted) {
      setState(() => _missingCredentials = false);
    }

    await eventsState.fetchEvents(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
    );
  }

  Future<void> _reload() async {
    final storage = _storage!;
    final eventsState = _eventsState!;

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isEmpty || projectId.isEmpty || apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure credentials in Settings.')),
        );
      }
      return;
    }

    await eventsState.fetchEvents(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
    );

    if (mounted && eventsState.error.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fetched ${eventsState.events.value.length} events.'),
        ),
      );
    } else if (mounted && eventsState.error.value != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch events: ${eventsState.error.value}'),
        ),
      );
    }
  }

  void _openConfigureColumns() async {
    final storage = _storage!;
    final eventsState = _eventsState!;

    final host = await storage.read(StorageService.keyHost) ?? '';
    final projectId = await storage.read(StorageService.keyProjectId) ?? '';
    final apiKey = await storage.read(StorageService.keyApiKey) ?? '';

    if (host.isNotEmpty && projectId.isNotEmpty && apiKey.isNotEmpty) {
      eventsState.loadAvailableColumns(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFFF5F4EF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Configure columns',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Visible columns (drag to reorder)',
                        style: TextStyle(color: Color(0xFF6F6A63)),
                      ),
                      const SizedBox(height: 12),
                      _buildVisibleColumnsList(eventsState, setDialogState),
                      const SizedBox(height: 16),
                      _buildAvailableColumnsSection(
                          eventsState, setDialogState),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _resetColumns(eventsState, setDialogState);
                            },
                            child: const Text('Reset to defaults'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              eventsState.saveVisibleColumns();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisibleColumnsList(
      EventsState eventsState, StateSetter setDialogState) {
    return SignalBuilder(
      builder: (context, _) {
        final keys = eventsState.visibleColumnKeys.value;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3DED6)),
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: keys.length,
            onReorder: (oldIndex, newIndex) {
              final updated = List<String>.from(keys);
              if (newIndex > oldIndex) newIndex -= 1;
              final item = updated.removeAt(oldIndex);
              updated.insert(newIndex, item);
              eventsState.visibleColumnKeys.value = updated;
              eventsState.saveVisibleColumns();
            },
            itemBuilder: (context, index) {
              final column = eventsState.columnForKey(keys[index]);
              return ListTile(
                key: ValueKey(column.key),
                leading: const Icon(Icons.drag_indicator),
                title: Text(column.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: Color(0xFFF15A24)),
                      onPressed: () {
                        final updated = List<String>.from(
                            eventsState.visibleColumnKeys.value);
                        updated.remove(column.key);
                        eventsState.visibleColumnKeys.value = updated;
                        eventsState.saveVisibleColumns();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvailableColumnsSection(
      EventsState eventsState, StateSetter setDialogState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3DED6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText:
                    'Search event properties, feature flags, person properties, sessions',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (value) {
                setDialogState(() {
                  _columnSearch = value;
                });
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3DED6)),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  child: SignalBuilder(
                    builder: (context, _) {
                      final available = eventsState.availableColumns.value;
                      return ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          _categoryChip(
                            'Event properties: ${_countForCategory(available, ColumnCategory.event)}',
                            selected:
                                _selectedCategory == ColumnCategory.event,
                            onTap: () => setDialogState(() {
                              _selectedCategory = ColumnCategory.event;
                            }),
                          ),
                          const SizedBox(height: 8),
                          _categoryChip(
                            'Feature flags: 0',
                            selected:
                                _selectedCategory == ColumnCategory.flags,
                            onTap: () => setDialogState(() {
                              _selectedCategory = ColumnCategory.flags;
                            }),
                          ),
                          const SizedBox(height: 8),
                          _categoryChip(
                            'Person properties: ${_countForCategory(available, ColumnCategory.person)}',
                            selected:
                                _selectedCategory == ColumnCategory.person,
                            onTap: () => setDialogState(() {
                              _selectedCategory = ColumnCategory.person;
                            }),
                          ),
                          const SizedBox(height: 8),
                          _categoryChip(
                            'Session properties: ${_countForCategory(available, ColumnCategory.session)}',
                            selected:
                                _selectedCategory == ColumnCategory.session,
                            onTap: () => setDialogState(() {
                              _selectedCategory = ColumnCategory.session;
                            }),
                          ),
                          const SizedBox(height: 8),
                          _categoryChip('SQL expression'),
                        ],
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE3DED6)),
                Expanded(
                  child: SignalBuilder(
                    builder: (context, _) {
                      final isLoadingCols =
                          eventsState.isLoadingColumns.value;
                      final available = eventsState.availableColumns.value;
                      final filtered = _filteredAvailableColumns(available);

                      if (isLoadingCols) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final column = filtered[index];
                          return _availableColumnRow(
                              column, eventsState);
                        },
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFE3DED6)),
                        itemCount: filtered.length,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    String text, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3DED6)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                selected ? const Color(0xFFF15A24) : const Color(0xFF1C1B19),
          ),
        ),
      ),
    );
  }

  Widget _availableColumnRow(ColumnOption column, EventsState eventsState) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.ssid_chart, size: 18),
      title: Text(column.label),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () {
          final current = eventsState.visibleColumnKeys.value;
          if (current.contains(column.key)) return;
          eventsState.visibleColumnKeys.value = [...current, column.key];
          eventsState.saveVisibleColumns();
        },
      ),
    );
  }

  void _resetColumns(EventsState eventsState, StateSetter setDialogState) {
    eventsState.visibleColumnKeys.value = _defaultVisibleKeys();
    eventsState.saveVisibleColumns();
  }

  List<ColumnOption> _filteredAvailableColumns(List<ColumnOption> available) {
    final search = _columnSearch.trim().toLowerCase();
    return available.where((column) {
      if (column.category != _selectedCategory) return false;
      if (search.isEmpty) return true;
      return column.label.toLowerCase().contains(search);
    }).toList();
  }

  int _countForCategory(List<ColumnOption> available, ColumnCategory category) {
    return available.where((c) => c.category == category).length;
  }

  List<String> _defaultVisibleKeys() {
    return [
      ColumnSpec.builtin(
        id: BuiltinColumnId.event,
        label: 'Event',
        flex: 2,
      ).key,
      ColumnSpec.builtin(
        id: BuiltinColumnId.person,
        label: 'Person',
        flex: 2,
      ).key,
      ColumnSpec.builtin(
        id: BuiltinColumnId.url,
        label: 'URL / Screen',
        flex: 3,
      ).key,
      ColumnSpec.builtin(
        id: BuiltinColumnId.library,
        label: 'Library',
        flex: 1,
      ).key,
      ColumnSpec.builtin(
        id: BuiltinColumnId.time,
        label: 'Time',
        flex: 1,
      ).key,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = _eventsState;
    if (eventsState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_missingCredentials) {
      return const EmptyState(
        icon: Icons.settings_outlined,
        title: 'No connection configured',
        subtitle: 'Configure your connection in Settings to get started.',
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFF15A24),
            labelColor: Color(0xFF1C1B19),
            unselectedLabelColor: Color(0xFF6F6A63),
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Sessions'),
              Tab(text: 'Live'),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildEventsTab(eventsState),
                _buildPlaceholder('Sessions view coming soon.'),
                _buildPlaceholder('Live view coming soon.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(EventsState eventsState) {
    return SignalBuilder(
      builder: (context, _) {
        final isLoading = eventsState.isLoading.value;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF1C1B19)),
                const SizedBox(width: 8),
                const Text(
                  'Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Chip(
                  label: const Text('PostHog default view'),
                  avatar: const Icon(Icons.tune, size: 16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE3DED6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Explore your events or see real-time events from your app or website.',
              style: TextStyle(color: Color(0xFF6F6A63)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('Last hour'),
                _filterChip('Select an event'),
                _filterChip('Filter', icon: Icons.add),
                _filterChip('Filter out internal and test users',
                    isToggle: true),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C1B19),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFE3DED6)),
                  ),
                ),
                const Spacer(),
                _headerButton(
                  'Configure columns',
                  Icons.view_column_outlined,
                  onPressed: _openConfigureColumns,
                ),
                const SizedBox(width: 8),
                _headerButton('Export', Icons.file_download_outlined),
                const SizedBox(width: 8),
                _headerButton('Open as new insight', Icons.open_in_new),
              ],
            ),
            const SizedBox(height: 16),
            _buildEventsTable(eventsState),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF6F6A63)),
      ),
    );
  }

  Widget _filterChip(String text, {IconData? icon, bool isToggle = false}) {
    return Chip(
      label: Text(text),
      avatar: icon != null
          ? Icon(icon, size: 16, color: const Color(0xFF1C1B19))
          : null,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE3DED6)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF1C1B19)),
    );
  }

  Widget _headerButton(String text, IconData icon, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1C1B19),
        side: const BorderSide(color: Color(0xFFE3DED6)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEventsTable(EventsState eventsState) {
    return SignalBuilder(
      builder: (context, _) {
        final isLoading = eventsState.isLoading.value;
        final events = eventsState.events.value;
        final visibleKeys = eventsState.visibleColumnKeys.value;
        final columns = visibleKeys.map(eventsState.columnForKey).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final tableMinWidth = _calculateTableMinWidth(columns);
            final tableWidth = constraints.maxWidth < tableMinWidth
                ? tableMinWidth
                : constraints.maxWidth;
            final columnWidths =
                _calculateColumnWidths(columns, tableWidth - 32);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3DED6)),
                  ),
                  child: Column(
                    children: [
                      _buildTableHeader(columns, columnWidths),
                      const Divider(height: 1, color: Color(0xFFE3DED6)),
                      if (isLoading && events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No events loaded yet.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Color(0xFFE3DED6)),
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return _buildEventRow(event, columns, columnWidths);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _calculateTableMinWidth(List<ColumnSpec> columns) {
    const baseWidth = 140.0;
    final totalFlex = columns.fold<int>(0, (sum, col) => sum + col.flex);
    return (totalFlex * baseWidth) + 32; // account for horizontal padding
  }

  List<double> _calculateColumnWidths(
    List<ColumnSpec> columns,
    double availableWidth,
  ) {
    final totalFlex = columns.fold<int>(0, (sum, col) => sum + col.flex);
    if (totalFlex == 0) {
      return List<double>.filled(
          columns.length, availableWidth / columns.length);
    }
    return columns
        .map((col) => availableWidth * (col.flex / totalFlex))
        .toList();
  }

  Widget _buildTableHeader(
    List<ColumnSpec> columns,
    List<double> widths,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(columns[i].label.toUpperCase()),
            ),
        ],
      ),
    );
  }

  Widget _buildEventRow(
    EventItem event,
    List<ColumnSpec> columns,
    List<double> widths,
  ) {
    return ListTile(
      dense: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < columns.length; i++)
            SizedBox(
              width: widths[i],
              child: _buildColumnCellWithTooltip(columns[i], event),
            ),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFFF5F4EF),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(event.prettyDetails),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColumnCellWithTooltip(ColumnSpec column, EventItem event) {
    final payload = _buildTooltipPayload(column, event);
    final message = const JsonEncoder.withIndent('  ').convert(payload);

    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 200),
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      child: _buildColumnCell(column, event),
    );
  }

  Widget _buildColumnCell(ColumnSpec column, EventItem event) {
    switch (column.kind) {
      case ColumnKind.builtin:
        final builtinId = column.id;
        if (builtinId == null) {
          return const Text('—');
        }
        switch (builtinId) {
          case BuiltinColumnId.event:
            return Text(event.eventName);
          case BuiltinColumnId.person:
            return Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFDAD1C3),
                  child: Text(
                    event.personInitial,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.distinctId,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          case BuiltinColumnId.url:
            return Text(
              event.urlLabel,
              overflow: TextOverflow.ellipsis,
            );
          case BuiltinColumnId.library:
            return Text(event.libraryLabel);
          case BuiltinColumnId.time:
            return Text(event.timeAgoLabel);
        }
      case ColumnKind.property:
        final key = column.propertyKey ?? '';
        final value = event.properties[key] ??
            (key.isNotEmpty && !key.startsWith(r'$')
                ? event.properties['\$$key']
                : null);
        return Text(
          value?.toString() ?? '—',
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Map<String, dynamic> _buildTooltipPayload(ColumnSpec column, EventItem event) {
    return {
      'label': column.label,
      'property_key': _columnPropertyKey(column),
      'category': _columnCategoryLabel(column),
      'value_preview': _truncateValue(_columnValuePreview(column, event)),
    };
  }

  String _columnPropertyKey(ColumnSpec column) {
    switch (column.kind) {
      case ColumnKind.builtin:
        switch (column.id) {
          case BuiltinColumnId.event:
            return 'event';
          case BuiltinColumnId.person:
            return 'distinct_id';
          case BuiltinColumnId.url:
            return r'$current_url';
          case BuiltinColumnId.library:
            return r'$lib';
          case BuiltinColumnId.time:
            return 'timestamp';
          case null:
            return column.label;
        }
      case ColumnKind.property:
        return column.propertyKey ?? column.label;
    }
  }

  String _columnCategoryLabel(ColumnSpec column) {
    final category = column.category ?? ColumnCategory.event;
    return category.name;
  }

  String _columnValuePreview(ColumnSpec column, EventItem event) {
    switch (column.kind) {
      case ColumnKind.builtin:
        switch (column.id) {
          case BuiltinColumnId.event:
            return event.eventName;
          case BuiltinColumnId.person:
            return event.distinctId;
          case BuiltinColumnId.url:
            return event.urlLabel;
          case BuiltinColumnId.library:
            return event.libraryLabel;
          case BuiltinColumnId.time:
            return event.timeAgoLabel;
          case null:
            return '—';
        }
      case ColumnKind.property:
        final key = column.propertyKey ?? '';
        final value = event.properties[key] ??
            (key.isNotEmpty && !key.startsWith(r'$')
                ? event.properties['\$$key']
                : null);
        return value?.toString() ?? '—';
    }
  }

  String _truncateValue(String value, {int maxLength = 120}) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1)}…';
  }
}
