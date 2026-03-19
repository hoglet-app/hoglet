class EventItem {
  final String uuid;
  final String event;
  final String distinctId;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  EventItem({
    required this.uuid,
    required this.event,
    required this.distinctId,
    required this.timestamp,
    this.properties = const {},
  });

  factory EventItem.fromHogQLRow(List<dynamic> row) {
    // Expected columns: uuid, event, distinct_id, timestamp, properties
    final propsRaw = row.length > 4 ? row[4] : null;
    Map<String, dynamic> properties = {};
    if (propsRaw is Map<String, dynamic>) {
      properties = propsRaw;
    } else if (propsRaw is String) {
      // Sometimes properties come as JSON string
      try {
        final parsed = _tryParseJson(propsRaw);
        if (parsed is Map<String, dynamic>) properties = parsed;
      } catch (_) {}
    }

    return EventItem(
      uuid: row[0]?.toString() ?? '',
      event: row[1]?.toString() ?? '',
      distinctId: row[2]?.toString() ?? '',
      timestamp: DateTime.tryParse(row[3]?.toString() ?? '') ?? DateTime.now(),
      properties: properties,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }

  String? getProperty(String key) {
    final value = properties[key];
    if (value == null) return null;
    return value.toString();
  }
}

dynamic _tryParseJson(String s) {
  // Avoid importing dart:convert here — caller handles it
  return s;
}
