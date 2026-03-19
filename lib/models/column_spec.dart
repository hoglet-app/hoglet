enum BuiltinColumnId { event, distinctId, timestamp, url, browser, os, device }

enum ColumnKind { builtin, eventProperty, personProperty }

class ColumnSpec {
  final String id;
  final String label;
  final ColumnKind kind;
  final BuiltinColumnId? builtinId;

  const ColumnSpec({
    required this.id,
    required this.label,
    required this.kind,
    this.builtinId,
  });

  /// Extract the value from an EventItem for this column.
  String? extractValue(dynamic event) {
    // event is an EventItem but we avoid the import cycle
    return null; // Extraction is handled in the screen
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'kind': kind.name,
        'builtinId': builtinId?.name,
      };

  factory ColumnSpec.fromJson(Map<String, dynamic> json) {
    return ColumnSpec(
      id: json['id'] as String,
      label: json['label'] as String,
      kind: ColumnKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => ColumnKind.eventProperty,
      ),
      builtinId: json['builtinId'] != null
          ? BuiltinColumnId.values.firstWhere(
              (b) => b.name == json['builtinId'],
              orElse: () => BuiltinColumnId.event,
            )
          : null,
    );
  }

  static const defaultColumns = [
    ColumnSpec(
      id: 'event',
      label: 'Event',
      kind: ColumnKind.builtin,
      builtinId: BuiltinColumnId.event,
    ),
    ColumnSpec(
      id: 'distinct_id',
      label: 'Person',
      kind: ColumnKind.builtin,
      builtinId: BuiltinColumnId.distinctId,
    ),
    ColumnSpec(
      id: 'timestamp',
      label: 'Time',
      kind: ColumnKind.builtin,
      builtinId: BuiltinColumnId.timestamp,
    ),
    ColumnSpec(
      id: 'url',
      label: 'URL',
      kind: ColumnKind.builtin,
      builtinId: BuiltinColumnId.url,
    ),
  ];

  static const allBuiltinColumns = [
    ColumnSpec(id: 'event', label: 'Event', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.event),
    ColumnSpec(id: 'distinct_id', label: 'Person', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.distinctId),
    ColumnSpec(id: 'timestamp', label: 'Time', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.timestamp),
    ColumnSpec(id: 'url', label: 'URL', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.url),
    ColumnSpec(id: 'browser', label: 'Browser', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.browser),
    ColumnSpec(id: 'os', label: 'OS', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.os),
    ColumnSpec(id: 'device', label: 'Device', kind: ColumnKind.builtin, builtinId: BuiltinColumnId.device),
  ];
}
