import 'dart:convert';

import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/column_spec.dart';
import '../models/event_item.dart';
import '../services/posthog_client.dart';
import '../services/storage_service.dart';

class EventsState {
  final events = Signal<List<EventItem>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);
  final visibleColumns = Signal<List<ColumnSpec>>(ColumnSpec.defaultColumns);
  final availableProperties = Signal<List<String>>([]);

  static const _columnsStorageKey = 'events_visible_columns';

  Future<void> fetchEvents(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
  ) async {
    isLoading.value = true;
    error.value = null;
    try {
      events.value = await client.fetchEvents(host, projectId, apiKey);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPropertyDefinitions(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
  ) async {
    try {
      final defs = await client.fetchPropertyDefinitions(
        host, projectId, apiKey,
        type: 'event',
      );
      availableProperties.value = defs
          .map((d) => d['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {
      // Non-critical — properties are optional
    }
  }

  Future<void> loadSavedColumns(StorageService storage) async {
    final json = await storage.read(_columnsStorageKey);
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        final columns = list
            .whereType<Map<String, dynamic>>()
            .map((j) => ColumnSpec.fromJson(j))
            .toList();
        if (columns.isNotEmpty) {
          visibleColumns.value = columns;
        }
      } catch (_) {
        // Fallback to defaults
      }
    }
  }

  Future<void> saveColumns(StorageService storage) async {
    final json = jsonEncode(
      visibleColumns.value.map((c) => c.toJson()).toList(),
    );
    await storage.write(_columnsStorageKey, json);
  }

  void addColumn(ColumnSpec column) {
    if (!visibleColumns.value.any((c) => c.id == column.id)) {
      visibleColumns.value = [...visibleColumns.value, column];
    }
  }

  void removeColumn(String columnId) {
    visibleColumns.value =
        visibleColumns.value.where((c) => c.id != columnId).toList();
  }

  void reorderColumns(int oldIndex, int newIndex) {
    final columns = List<ColumnSpec>.from(visibleColumns.value);
    if (newIndex > oldIndex) newIndex--;
    final item = columns.removeAt(oldIndex);
    columns.insert(newIndex, item);
    visibleColumns.value = columns;
  }

  void dispose() {
    events.dispose();
    isLoading.dispose();
    error.dispose();
    visibleColumns.dispose();
    availableProperties.dispose();
  }
}
