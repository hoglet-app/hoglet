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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF5F4EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3DED6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Configure columns',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _resetColumns(eventsState);
                            },
                            child: const Text('Reset'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          // Visible columns section
                          const Text(
                            'VISIBLE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Color(0xFF6F6A63),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildVisibleColumnsList(eventsState),
                          const SizedBox(height: 20),
                          // Category filter chips
                          const Text(
                            'ADD COLUMNS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Color(0xFF6F6A63),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCategoryChips(eventsState, setSheetState),
                          const SizedBox(height: 12),
                          // Search
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 20),
                              hintText: 'Search properties...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE3DED6)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE3DED6)),
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                _columnSearch = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // Available columns list
                          _buildAvailableColumnsList(eventsState),
                        ],
                      ),
                    ),
                    // Bottom action bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFFE3DED6))),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            eventsState.saveVisibleColumns();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF15A24),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChips(EventsState eventsState, StateSetter setSheetState) {
    return SignalBuilder(
      builder: (context, _) {
        final available = eventsState.availableColumns.value;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _categoryChip(
              'Event (${_countForCategory(available, ColumnCategory.event)})',
              selected: _selectedCategory == ColumnCategory.event,
              onTap: () => setSheetState(() => _selectedCategory = ColumnCategory.event),
            ),
            _categoryChip(
              'Person (${_countForCategory(available, ColumnCategory.person)})',
              selected: _selectedCategory == ColumnCategory.person,
              onTap: () => setSheetState(() => _selectedCategory = ColumnCategory.person),
            ),
            _categoryChip(
              'Session (${_countForCategory(available, ColumnCategory.session)})',
              selected: _selectedCategory == ColumnCategory.session,
              onTap: () => setSheetState(() => _selectedCategory = ColumnCategory.session),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisibleColumnsList(EventsState eventsState) {
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
            },
            itemBuilder: (context, index) {
              final column = eventsState.columnForKey(keys[index]);
              return ListTile(
                key: ValueKey(column.key),
                dense: true,
                leading: const Icon(Icons.drag_indicator, size: 20, color: Color(0xFF9E9890)),
                title: Text(column.label, style: const TextStyle(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Color(0xFFF15A24)),
                  onPressed: () {
                    final updated = List<String>.from(
                      eventsState.visibleColumnKeys.value,
                    );
                    updated.remove(column.key);
                    eventsState.visibleColumnKeys.value = updated;
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvailableColumnsList(EventsState eventsState) {
    return SignalBuilder(
      builder: (context, _) {
        final isLoadingCols = eventsState.isLoadingColumns.value;
        final available = eventsState.availableColumns.value;
        final filtered = _filteredAvailableColumns(available);
        final visibleKeys = eventsState.visibleColumnKeys.value;

        if (isLoadingCols && available.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                _columnSearch.isEmpty
                    ? 'No properties in this category'
                    : 'No results for "$_columnSearch"',
                style: const TextStyle(color: Color(0xFF6F6A63)),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3DED6)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFE3DED6),
            ),
            itemBuilder: (context, index) {
              final column = filtered[index];
              final alreadyAdded = visibleKeys.contains(column.key);
              return ListTile(
                dense: true,
                title: Text(
                  column.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: alreadyAdded ? const Color(0xFF9E9890) : const Color(0xFF1C1B19),
                  ),
                ),
                trailing: alreadyAdded
                    ? const Icon(Icons.check, size: 18, color: Color(0xFF9E9890))
                    : const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFFF15A24)),
                onTap: alreadyAdded
                    ? null
                    : () {
                        final current = eventsState.visibleColumnKeys.value;
                        eventsState.visibleColumnKeys.value = [...current, column.key];
                      },
              );
            },
          ),
        );
      },
    );
  }

  Widget _categoryChip(
    String text, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE7) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFF15A24) : const Color(0xFFE3DED6),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: selected ? const Color(0xFFF15A24) : const Color(0xFF1C1B19),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _resetColumns(EventsState eventsState) {
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
