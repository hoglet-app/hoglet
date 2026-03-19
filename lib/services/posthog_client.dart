import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import '../models/event_item.dart';
import '../models/feature_flag.dart';
import '../models/insight.dart';
import 'posthog_api_error.dart';

class PosthogClient {
  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final reason = response.reasonPhrase ?? 'Request failed';

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw AuthenticationError(response.statusCode, reason);
    }

    if (response.statusCode == 429) {
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      throw RateLimitError(response.statusCode, reason, retryAfterSeconds: retryAfter);
    }

    throw PosthogApiError(response.statusCode, reason);
  }

  Future<http.Response> _get(Uri uri, String apiKey,
      {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(timeout);
      _checkResponse(response);
      return response;
    } on SocketException catch (e) {
      throw NetworkError('No internet connection', cause: e);
    } on TimeoutException {
      throw NetworkError('Request timed out');
    }
  }

  Future<http.Response> _post(
      Uri uri, String apiKey, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      ).timeout(timeout);
      _checkResponse(response);
      return response;
    } on SocketException catch (e) {
      throw NetworkError('No internet connection', cause: e);
    } on TimeoutException {
      throw NetworkError('Request timed out');
    }
  }

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

    final response = await _post(uri, apiKey, body);

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
      final response = await _get(next, apiKey);

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

  Future<List<Map<String, dynamic>>> fetchProjects({
    required String host,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$host/api/projects/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['results'] is List) {
      return (decoded['results'] as List).cast<Map<String, dynamic>>();
    }
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchOrganizations({
    required String host,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$host/api/organizations/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['results'] is List) {
      return (decoded['results'] as List).cast<Map<String, dynamic>>();
    }
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Dashboard>> fetchDashboards({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/dashboards/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body);
    final results = decoded is Map && decoded['results'] is List
        ? decoded['results'] as List
        : decoded is List ? decoded : [];
    return results.map((d) => Dashboard.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<Dashboard> fetchDashboard({
    required String host,
    required String projectId,
    required String apiKey,
    required int dashboardId,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/dashboards/$dashboardId/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Dashboard.fromJson(decoded);
  }

  Future<Insight> fetchInsight({
    required String host,
    required String projectId,
    required String apiKey,
    required int insightId,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/insights/$insightId/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return Insight.fromJson(decoded);
  }

  Future<List<Insight>> fetchInsights({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/insights/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body);
    final results = decoded is Map && decoded['results'] is List
        ? decoded['results'] as List
        : decoded is List ? decoded : [];
    return results.map((d) => Insight.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<http.Response> _patch(Uri uri, String apiKey, Map<String, dynamic> body,
      {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      ).timeout(timeout);
      _checkResponse(response);
      return response;
    } on SocketException catch (e) {
      throw NetworkError('No internet connection', cause: e);
    } on TimeoutException {
      throw NetworkError('Request timed out');
    }
  }

  Future<List<FeatureFlag>> fetchFeatureFlags({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/feature_flags/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body);
    final results = decoded is Map && decoded['results'] is List
        ? decoded['results'] as List
        : decoded is List ? decoded : [];
    return results.map((d) => FeatureFlag.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<FeatureFlag> fetchFeatureFlag({
    required String host,
    required String projectId,
    required String apiKey,
    required int flagId,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/feature_flags/$flagId/');
    final response = await _get(uri, apiKey);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return FeatureFlag.fromJson(decoded);
  }

  Future<FeatureFlag> toggleFeatureFlag({
    required String host,
    required String projectId,
    required String apiKey,
    required int flagId,
    required bool active,
  }) async {
    final uri = Uri.parse('$host/api/environments/$projectId/feature_flags/$flagId/');
    final response = await _patch(uri, apiKey, {'active': active});
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return FeatureFlag.fromJson(decoded);
  }
}
