import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import '../models/feature_flag.dart';
import '../models/insight.dart';
import 'posthog_api_error.dart';

class PosthogClient {
  final http.Client _httpClient;

  PosthogClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  Uri _uri(String host, String path, [Map<String, String>? queryParams]) {
    final base = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return Uri.parse('$base$path').replace(queryParameters: queryParams);
  }

  Future<dynamic> _get(
    String host,
    String path,
    String apiKey, {
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? queryParams,
  }) async {
    try {
      final response = await _httpClient
          .get(_uri(host, path, queryParams), headers: _headers(apiKey))
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkError('Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkError('Connection failed', cause: e);
    }
  }

  Future<dynamic> _post(
    String host,
    String path,
    String apiKey,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final response = await _httpClient
          .post(
            _uri(host, path),
            headers: _headers(apiKey),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkError('Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkError('Connection failed', cause: e);
    }
  }

  Future<dynamic> _patch(
    String host,
    String path,
    String apiKey,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final response = await _httpClient
          .patch(
            _uri(host, path),
            headers: _headers(apiKey),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw NetworkError('Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkError('Connection failed', cause: e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 429) {
      throw RateLimitError.fromHeaders(
        response.statusCode,
        response.body,
        response.headers,
      );
    }

    throw PosthogApiError.fromResponse(response.statusCode, response.body);
  }

  // -- Projects & Organizations --

  Future<List<Map<String, dynamic>>> fetchProjects(
    String host,
    String apiKey,
  ) async {
    final data = await _get(host, '/api/projects/', apiKey);
    final results = data['results'] as List? ?? data as List;
    return results.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchOrganizations(
    String host,
    String apiKey,
  ) async {
    final data = await _get(host, '/api/organizations/', apiKey);
    final results = data['results'] as List? ?? data as List;
    return results.cast<Map<String, dynamic>>();
  }

  /// Quick connection test — fetches projects and returns true if successful.
  Future<bool> testConnection(String host, String apiKey) async {
    try {
      await fetchProjects(host, apiKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -- Dashboards --

  Future<List<Dashboard>> fetchDashboards(
    String host,
    String projectId,
    String apiKey,
  ) async {
    final data = await _get(host, '/api/environments/$projectId/dashboards/', apiKey);
    final results = data['results'] as List? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((json) => Dashboard.fromJson(json))
        .toList();
  }

  Future<Dashboard> fetchDashboard(
    String host,
    String projectId,
    String apiKey,
    int dashboardId,
  ) async {
    final data = await _get(
      host,
      '/api/environments/$projectId/dashboards/$dashboardId/',
      apiKey,
    );
    return Dashboard.fromJson(data as Map<String, dynamic>);
  }

  // -- Insights --

  Future<List<Insight>> fetchInsights(
    String host,
    String projectId,
    String apiKey,
  ) async {
    final data = await _get(host, '/api/environments/$projectId/insights/', apiKey);
    final results = data['results'] as List? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((json) => Insight.fromJson(json))
        .toList();
  }

  Future<Insight> fetchInsight(
    String host,
    String projectId,
    String apiKey,
    int insightId,
  ) async {
    final data = await _get(
      host,
      '/api/environments/$projectId/insights/$insightId/',
      apiKey,
      timeout: const Duration(seconds: 30),
    );
    return Insight.fromJson(data as Map<String, dynamic>);
  }

  // -- Feature Flags --

  Future<List<FeatureFlag>> fetchFeatureFlags(
    String host,
    String projectId,
    String apiKey,
  ) async {
    final data = await _get(host, '/api/environments/$projectId/feature_flags/', apiKey);
    final results = data['results'] as List? ?? [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((json) => FeatureFlag.fromJson(json))
        .toList();
  }

  Future<FeatureFlag> fetchFeatureFlag(
    String host,
    String projectId,
    String apiKey,
    int flagId,
  ) async {
    final data = await _get(
      host,
      '/api/environments/$projectId/feature_flags/$flagId/',
      apiKey,
    );
    return FeatureFlag.fromJson(data as Map<String, dynamic>);
  }

  Future<FeatureFlag> toggleFeatureFlag(
    String host,
    String projectId,
    String apiKey,
    int flagId,
    bool active,
  ) async {
    final data = await _patch(
      host,
      '/api/environments/$projectId/feature_flags/$flagId/',
      apiKey,
      {'active': active},
    );
    return FeatureFlag.fromJson(data as Map<String, dynamic>);
  }

  void dispose() {
    _httpClient.close();
  }
}
