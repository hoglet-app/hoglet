import 'dart:convert';

import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/column_spec.dart';
import '../models/event_item.dart';
import '../services/posthog_client.dart';
import '../services/storage_service.dart';

class EventsState {
  EventsState({required this.client, required this.storage});

  final PosthogClient client;
  final StorageService storage;

  final events = Signal<List<EventItem>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  final visibleColumnKeys = Signal<List<String>>([]);
  final columnRegistry = Signal<Map<String, ColumnSpec>>({});
  final availableColumns = Signal<List<ColumnOption>>([]);
  final isLoadingColumns = Signal(false);

  void registerBuiltinColumns() {
    final defaults = [
      ColumnSpec.builtin(
        id: BuiltinColumnId.event,
        label: 'Event',
        flex: 2,
      ),
      ColumnSpec.builtin(
        id: BuiltinColumnId.person,
        label: 'Person',
        flex: 2,
      ),
      ColumnSpec.builtin(
        id: BuiltinColumnId.url,
        label: 'URL / Screen',
        flex: 3,
      ),
      ColumnSpec.builtin(
        id: BuiltinColumnId.library,
        label: 'Library',
        flex: 1,
      ),
      ColumnSpec.builtin(
        id: BuiltinColumnId.time,
        label: 'Time',
        flex: 1,
      ),
    ];

    final registry = Map<String, ColumnSpec>.from(columnRegistry.value);
    for (final spec in defaults) {
      registry[spec.key] = spec;
    }
    columnRegistry.value = registry;

    if (visibleColumnKeys.value.isEmpty) {
      visibleColumnKeys.value = _defaultVisibleKeys();
    }
  }

  Future<void> loadVisibleColumns() async {
    final raw = await storage.read(StorageService.keyVisibleColumns);
    _restoreVisibleColumns(raw);
  }

  Future<void> saveVisibleColumns() async {
    await storage.write(
      StorageService.keyVisibleColumns,
      jsonEncode(visibleColumnKeys.value),
    );
  }

  Future<void> fetchEvents({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await client.fetchEvents(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
      events.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAvailableColumns({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    if (isLoadingColumns.value) return;

    isLoadingColumns.value = true;

    try {
      final eventProps = await client.fetchPropertyDefinitions(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        type: 'event',
      );
      final personProps = await client.fetchPropertyDefinitions(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        type: 'person',
      );
      final sessionProps = await client.fetchPropertyDefinitions(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        type: 'session',
      );

      final options = <ColumnOption>[
        ...eventProps.map(
          (name) => ColumnOption.property(
            category: ColumnCategory.event,
            propertyKey: name,
          ),
        ),
        ...personProps.map(
          (name) => ColumnOption.property(
            category: ColumnCategory.person,
            propertyKey: name,
          ),
        ),
        ...sessionProps.map(
          (name) => ColumnOption.property(
            category: ColumnCategory.session,
            propertyKey: name,
          ),
        ),
      ];

      availableColumns.value = options;
      _refreshRegistry();
    } catch (_) {
      // ignore errors; UI will show empty list
    } finally {
      isLoadingColumns.value = false;
    }
  }

  ColumnSpec columnForKey(String key) {
    return columnRegistry.value[key] ?? ColumnSpec.fallback(key);
  }

  void _refreshRegistry() {
    final registry = Map<String, ColumnSpec>.from(columnRegistry.value);
    for (final option in availableColumns.value) {
      final spec = ColumnSpec.property(
        propertyKey: option.propertyKey,
        label: option.label,
        category: option.category,
      );
      registry[spec.key] = spec;
    }
    columnRegistry.value = registry;

    if (visibleColumnKeys.value.isEmpty) {
      visibleColumnKeys.value = _defaultVisibleKeys();
    }
  }

  void _restoreVisibleColumns(String? raw) {
    if (raw == null || raw.isEmpty) {
      if (visibleColumnKeys.value.isEmpty) {
        visibleColumnKeys.value = _defaultVisibleKeys();
      }
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        visibleColumnKeys.value = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}

    if (visibleColumnKeys.value.isEmpty) {
      visibleColumnKeys.value = _defaultVisibleKeys();
    }
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

  void dispose() {
    events.dispose();
    isLoading.dispose();
    error.dispose();
    visibleColumnKeys.dispose();
    columnRegistry.dispose();
    availableColumns.dispose();
    isLoadingColumns.dispose();
  }
}
