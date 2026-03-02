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

  Future<List<String>> fetchPropertyDefinitions({
    required String host,
    required String projectId,
    required String apiKey,
    required String type,
  }) async {
    final candidates = [
      Uri.parse(
        '$host/api/projects/$projectId/property_definitions/?type=$type&limit=100',
      ),
      Uri.parse(
        '$host/api/property_definition/?type=$type&limit=100&project_id=$projectId',
      ),
      Uri.parse(
        '$host/api/property_definition/?type=$type&limit=100',
      ),
    ];

    List<dynamic> results = [];
    Exception? lastError;

    for (final uri in candidates) {
      try {
        results = await _fetchPagedResults(
          uri: uri,
          apiKey: apiKey,
        );
        if (results.isNotEmpty) {
          break;
        }
      } on Exception catch (error) {
        lastError = error;
      }
    }

    if (results.isEmpty && lastError != null) {
      throw lastError;
    }

    return results
        .map((item) {
          if (item is Map && item['name'] != null) {
            return item['name'].toString();
          }
          if (item is Map && item['property'] != null) {
            return item['property'].toString();
          }
          return item.toString();
        })
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<List<dynamic>> _fetchPagedResults({
    required Uri uri,
    required String apiKey,
  }) async {
    final allResults = <dynamic>[];
    Uri? next = uri;

    while (next != null) {
      final response = await http.get(
        next,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode != 200) {
        final reason = response.reasonPhrase ?? 'Request failed';
        throw Exception('$reason (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['results'] is List) {
        allResults.addAll(decoded['results'] as List);
      }

      if (decoded is Map && decoded['next'] is String) {
        final nextUrl = decoded['next'] as String;
        next = nextUrl.isEmpty ? null : Uri.parse(nextUrl);
      } else {
        next = null;
      }
    }

    return allResults;
  }
}
