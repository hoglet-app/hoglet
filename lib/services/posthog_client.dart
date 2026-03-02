import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/event_item.dart';

class PosthogClient {
  Future<List<EventItem>> fetchEvents({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$host/api/projects/$projectId/query/');
    final body = {
      'name': 'hoglet_live_events',
      'query': {
        'kind': 'HogQLQuery',
        'query':
            'SELECT uuid, event, distinct_id, timestamp, properties FROM events ORDER BY timestamp DESC LIMIT 100',
      },
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final reason = response.reasonPhrase ?? 'Request failed';
      throw Exception('$reason (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    final results = decoded is Map && decoded['results'] is List
        ? decoded['results'] as List
        : <dynamic>[];

    final parsed = <EventItem>[];
    for (final row in results) {
      if (row is List && row.length >= 5) {
        parsed.add(EventItem.fromList(row));
      } else if (row is Map) {
        parsed.add(EventItem.fromMap(row));
      }
    }

    return parsed;
  }
}
