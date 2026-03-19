import 'dart:convert';

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
    } else if (propsRaw is Map) {
      properties = Map<String, dynamic>.from(propsRaw);
    } else if (propsRaw is String && propsRaw.isNotEmpty) {
      try {
        final parsed = jsonDecode(propsRaw);
        if (parsed is Map<String, dynamic>) {
          properties = parsed;
        } else if (parsed is Map) {
          properties = Map<String, dynamic>.from(parsed);
        }
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

  String get fullTimestamp {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String? getProperty(String key) {
    final value = properties[key];
    if (value == null) return null;
    return value.toString();
  }

  /// URL or screen this event occurred on
  String? get pageUrl => getProperty('\$current_url') ?? getProperty('\$screen_name');
  String? get browser => getProperty('\$browser');
  String? get os => getProperty('\$os');
  String? get deviceType => getProperty('\$device_type');
  String? get city => getProperty('\$geoip_city_name');
  String? get countryCode => getProperty('\$geoip_country_code');
  String? get referrer => getProperty('\$referring_domain');
  String? get lib => getProperty('\$lib');
}
