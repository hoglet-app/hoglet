import 'dart:convert';

import 'package:characters/characters.dart';

class EventItem {
  EventItem({
    required this.uuid,
    required this.eventName,
    required this.distinctId,
    required this.timestamp,
    required this.properties,
  });

  final String uuid;
  final String eventName;
  final String distinctId;
  final DateTime? timestamp;
  final Map<String, dynamic> properties;

  factory EventItem.fromList(List<dynamic> row) {
    return EventItem(
      uuid: row[0]?.toString() ?? '',
      eventName: row[1]?.toString() ?? '',
      distinctId: row[2]?.toString() ?? '',
      timestamp: _parseTimestamp(row[3]),
      properties: _parseProperties(row[4]),
    );
  }

  factory EventItem.fromMap(Map<dynamic, dynamic> row) {
    return EventItem(
      uuid: row['uuid']?.toString() ?? '',
      eventName: row['event']?.toString() ?? '',
      distinctId: row['distinct_id']?.toString() ?? '',
      timestamp: _parseTimestamp(row['timestamp']),
      properties: _parseProperties(row['properties']),
    );
  }

  String get personInitial {
    if (distinctId.isEmpty) return '•';
    return distinctId.characters.first.toUpperCase();
  }

  String get urlLabel {
    final url = properties[r'$current_url']?.toString();
    final screen = properties[r'$screen']?.toString();
    return url ?? screen ?? '—';
  }

  String get libraryLabel {
    return properties[r'$lib']?.toString() ?? 'web';
  }

  String get timeAgoLabel {
    if (timestamp == null) return 'unknown';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String get prettyDetails {
    final buffer = StringBuffer();
    buffer.writeln('UUID: $uuid');
    buffer.writeln('Event: $eventName');
    buffer.writeln('Distinct ID: $distinctId');
    buffer.writeln('Timestamp: ${timestamp?.toIso8601String() ?? 'unknown'}');
    buffer.writeln('Properties:');
    buffer.writeln(const JsonEncoder.withIndent('  ').convert(properties));
    return buffer.toString();
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic> _parseProperties(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return {};
  }
}
