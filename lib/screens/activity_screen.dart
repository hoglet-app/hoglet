import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../di/providers.dart';
import '../models/column_spec.dart';
import '../models/event_item.dart';
import '../services/storage_service.dart';
import '../state/events_state.dart';
import '../widgets/error_view.dart';
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
          const SnackBar(
            content: Text('Please configure credentials in Settings.'),
          ),
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
          content:
              Text('Failed to fetch events: ${eventsState.error.value}'),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
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
                        eventsState,
                        setDialogState,
                      ),
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
    EventsState eventsState,
    StateSetter setDialogState,
  ) {
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
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFF15A24),
                      ),
                      onPressed: () {
                        final updated = List<String>.from(
                          eventsState.visibleColumnKeys.value,
                        );
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
    EventsState eventsState,
    StateSetter setDialogState,
  ) {
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
                      final filtered =
                          _filteredAvailableColumns(available);

                      if (isLoadingCols) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final column = filtered[index];
                          return _availableColumnRow(column, eventsState);
                        },
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFFE3DED6),
                        ),
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
            color: selected
                ? const Color(0xFFF15A24)
                : const Color(0xFF1C1B19),
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

  int _countForCategory(
    List<ColumnOption> available,
    ColumnCategory category,
  ) {
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

  void _openEventDetail(EventItem event) {
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

    return SignalBuilder(
      builder: (context, _) {
        final isLoading = eventsState.isLoading.value;
        final events = eventsState.events.value;
        final errorValue = eventsState.error.value;

        // Error state with retry
        if (errorValue != null && events.isEmpty) {
          return ErrorView(error: errorValue, onRetry: _reload);
        }

        // Loading state — first load
        if (isLoading && events.isEmpty) {
          return const ShimmerList();
        }

        // Empty state — loaded but no events
        if (!isLoading && events.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No events yet',
            subtitle: 'Pull down to refresh or check your configuration.',
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              color: const Color(0xFFF15A24),
              onRefresh: _reload,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _EventCard(
                    event: events[index],
                    onTap: () => _openEventDetail(events[index]),
                  );
                },
              ),
            ),
            // Floating action area — bottom right
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'configure',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C1B19),
                    onPressed: _openConfigureColumns,
                    child: const Icon(Icons.tune, size: 20),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'reload',
                    backgroundColor: const Color(0xFFF15A24),
                    foregroundColor: Colors.white,
                    onPressed: isLoading ? null : _reload,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single event card for the mobile activity list.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
  });

  final EventItem event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3DED6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Event name + time
            Row(
              children: [
                const Icon(
                  Icons.bolt,
                  size: 16,
                  color: Color(0xFFF15A24),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.eventName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1B19),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  event.timeAgoLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6F6A63),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: Person + library badge
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFFDAD1C3),
                  child: Text(
                    event.personInitial,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF1C1B19)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.distinctId,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6F6A63),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F4EF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE3DED6)),
                  ),
                  child: Text(
                    event.libraryLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6F6A63),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
