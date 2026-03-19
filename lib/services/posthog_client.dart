import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/action.dart';
import '../models/alert.dart';
import '../models/annotation.dart';
import '../models/cohort.dart';
import '../models/dashboard.dart';
import '../models/early_access_feature.dart';
import '../models/error_group.dart';
import '../models/event_definition.dart';
import '../models/event_item.dart';
import '../models/experiment.dart';
import '../models/feature_flag.dart';
import '../models/group.dart';
import '../models/insight.dart';
import '../models/log_entry.dart';
import '../models/person.dart';
import '../models/product_tour.dart';
import '../models/sql_result.dart';
import '../models/survey.dart';
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

  // -- Events (HogQL) --

  Future<List<EventItem>> fetchEvents(
    String host,
    String projectId,
    String apiKey, {
    int limit = 100,
  }) async {
    final data = await _post(
      host,
      '/api/projects/$projectId/query/',
      apiKey,
      {
        'query': {
          'kind': 'HogQLQuery',
          'query':
              'SELECT uuid, event, distinct_id, timestamp, properties '
              'FROM events ORDER BY timestamp DESC LIMIT $limit',
        },
      },
    );

    final results = <EventItem>[];
    final rows = data['results'] as List? ?? [];
    for (final row in rows) {
      if (row is List) {
        results.add(EventItem.fromHogQLRow(row));
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> fetchPropertyDefinitions(
    String host,
    String projectId,
    String apiKey, {
    String type = 'event', // event, person, session
    int limit = 100,
  }) async {
    // Try multiple URL patterns for compatibility
    final paths = [
      '/api/projects/$projectId/property_definitions/?type=$type&limit=$limit',
      '/api/environments/$projectId/property_definitions/?type=$type&limit=$limit',
    ];

    for (final path in paths) {
      try {
        final data = await _get(host, path, apiKey);
        final results = data['results'] as List? ?? [];
        return results.cast<Map<String, dynamic>>();
      } catch (e) {
        if (e is PosthogApiError && e.statusCode == 404) continue;
        rethrow;
      }
    }
    return [];
  }

  // -- Persons --

  Future<({List<Person> persons, bool hasNext})> fetchPersons(
    String host, String projectId, String apiKey, {
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, String>{'limit': limit.toString(), 'offset': offset.toString()};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _get(host, '/api/environments/$projectId/persons/', apiKey, queryParams: params);
    final results = data['results'] as List? ?? [];
    final hasNext = data['next'] != null;
    return (
      persons: results.whereType<Map<String, dynamic>>().map((j) => Person.fromJson(j)).toList(),
      hasNext: hasNext,
    );
  }

  Future<Person> fetchPerson(String host, String projectId, String apiKey, int personId) async {
    final data = await _get(host, '/api/environments/$projectId/persons/$personId/', apiKey);
    return Person.fromJson(data as Map<String, dynamic>);
  }

  // -- Cohorts --

  Future<List<Cohort>> fetchCohorts(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/projects/$projectId/cohorts/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => Cohort.fromJson(j)).toList();
  }

  Future<Cohort> fetchCohort(String host, String projectId, String apiKey, int cohortId) async {
    final data = await _get(host, '/api/projects/$projectId/cohorts/$cohortId/', apiKey);
    return Cohort.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Person>> fetchCohortPersons(String host, String projectId, String apiKey, int cohortId) async {
    final data = await _get(host, '/api/projects/$projectId/cohorts/$cohortId/persons/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => Person.fromJson(j)).toList();
  }

  // -- Experiments --

  Future<List<Experiment>> fetchExperiments(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/environments/$projectId/experiments/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => Experiment.fromJson(j)).toList();
  }

  Future<Experiment> fetchExperiment(String host, String projectId, String apiKey, int id) async {
    final data = await _get(host, '/api/environments/$projectId/experiments/$id/', apiKey);
    return Experiment.fromJson(data as Map<String, dynamic>);
  }

  // -- Surveys --

  Future<List<Survey>> fetchSurveys(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/environments/$projectId/surveys/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => Survey.fromJson(j)).toList();
  }

  Future<Survey> fetchSurvey(String host, String projectId, String apiKey, int id) async {
    final data = await _get(host, '/api/environments/$projectId/surveys/$id/', apiKey);
    return Survey.fromJson(data as Map<String, dynamic>);
  }

  // -- Error Tracking --

  Future<List<ErrorGroup>> fetchErrorGroups(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/environments/$projectId/error_tracking/groups/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => ErrorGroup.fromJson(j)).toList();
  }

  Future<ErrorGroup> fetchErrorGroup(String host, String projectId, String apiKey, String errorId) async {
    final data = await _get(host, '/api/environments/$projectId/error_tracking/groups/$errorId/', apiKey);
    return ErrorGroup.fromJson(data as Map<String, dynamic>);
  }

  Future<ErrorGroup> updateErrorStatus(String host, String projectId, String apiKey, String errorId, String status) async {
    final data = await _patch(host, '/api/environments/$projectId/error_tracking/groups/$errorId/', apiKey, {'status': status});
    return ErrorGroup.fromJson(data as Map<String, dynamic>);
  }

  // -- Alerts --

  Future<List<AlertItem>> fetchAlerts(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/environments/$projectId/alerts/', apiKey);
    final results = data['results'] as List? ?? data as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => AlertItem.fromJson(j)).toList();
  }

  Future<AlertItem> fetchAlert(String host, String projectId, String apiKey, int id) async {
    final data = await _get(host, '/api/environments/$projectId/alerts/$id/', apiKey);
    return AlertItem.fromJson(data as Map<String, dynamic>);
  }

  Future<AlertItem> dismissAlert(String host, String projectId, String apiKey, int id) async {
    final data = await _patch(host, '/api/environments/$projectId/alerts/$id/', apiKey, {'state': 'snoozed'});
    return AlertItem.fromJson(data as Map<String, dynamic>);
  }

  // -- Web Analytics --

  Future<Map<String, dynamic>> fetchWebAnalytics(String host, String projectId, String apiKey) async {
    final data = await _post(host, '/api/projects/$projectId/query/', apiKey, {
      'query': {'kind': 'HogQLQuery', 'query': 'SELECT count() as pageviews, uniq(distinct_id) as visitors, uniq(properties.\$session_id) as sessions FROM events WHERE event = \'\$pageview\' AND timestamp > now() - INTERVAL 7 DAY'},
    });
    final results = data['results'] as List? ?? [];
    if (results.isNotEmpty && results.first is List) {
      final row = results.first as List;
      return {'pageviews': row.isNotEmpty ? row[0] : 0, 'visitors': row.length > 1 ? row[1] : 0, 'sessions': row.length > 2 ? row[2] : 0};
    }
    return {};
  }

  // -- Web Analytics (Extended) --

  Future<List<List<dynamic>>> fetchTopPages(String host, String projectId, String apiKey) async {
    final data = await _post(host, '/api/projects/$projectId/query/', apiKey, {
      'query': {'kind': 'HogQLQuery', 'query': "SELECT properties.\$pathname as path, count() as views, uniq(distinct_id) as visitors FROM events WHERE event = '\$pageview' AND timestamp > now() - INTERVAL 7 DAY GROUP BY path ORDER BY views DESC LIMIT 10"},
    });
    return (data['results'] as List? ?? []).whereType<List>().toList();
  }

  Future<List<List<dynamic>>> fetchTopReferrers(String host, String projectId, String apiKey) async {
    final data = await _post(host, '/api/projects/$projectId/query/', apiKey, {
      'query': {'kind': 'HogQLQuery', 'query': "SELECT properties.\$referring_domain as referrer, count() as views FROM events WHERE event = '\$pageview' AND timestamp > now() - INTERVAL 7 DAY AND referrer != '' AND referrer IS NOT NULL GROUP BY referrer ORDER BY views DESC LIMIT 10"},
    });
    return (data['results'] as List? ?? []).whereType<List>().toList();
  }

  Future<List<List<dynamic>>> fetchTopBrowsers(String host, String projectId, String apiKey) async {
    final data = await _post(host, '/api/projects/$projectId/query/', apiKey, {
      'query': {'kind': 'HogQLQuery', 'query': "SELECT properties.\$browser as browser, count() as views FROM events WHERE event = '\$pageview' AND timestamp > now() - INTERVAL 7 DAY AND browser IS NOT NULL GROUP BY browser ORDER BY views DESC LIMIT 8"},
    });
    return (data['results'] as List? ?? []).whereType<List>().toList();
  }

  // -- Session Recordings --

  Future<List<Map<String, dynamic>>> fetchSessionRecordings(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/environments/$projectId/session_recordings/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.cast<Map<String, dynamic>>();
  }

  // -- Annotations --

  Future<List<Annotation>> fetchAnnotations(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/projects/$projectId/annotations/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => Annotation.fromJson(j)).toList();
  }

  Future<Annotation> fetchAnnotation(String host, String projectId, String apiKey, int id) async {
    final data = await _get(host, '/api/projects/$projectId/annotations/$id/', apiKey);
    return Annotation.fromJson(data as Map<String, dynamic>);
  }

  Future<Annotation> createAnnotation(
    String host, String projectId, String apiKey, {
    required String content,
    required String dateMarker,
    String scope = 'project',
    int? dashboardItem,
    int? dashboardId,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'date_marker': dateMarker,
      'scope': scope,
    };
    if (dashboardItem != null) body['dashboard_item'] = dashboardItem;
    if (dashboardId != null) body['dashboard_id'] = dashboardId;
    final data = await _post(host, '/api/projects/$projectId/annotations/', apiKey, body);
    return Annotation.fromJson(data as Map<String, dynamic>);
  }

  Future<Annotation> updateAnnotation(
    String host, String projectId, String apiKey, int id, {
    String? content,
    String? dateMarker,
    String? scope,
  }) async {
    final body = <String, dynamic>{};
    if (content != null) body['content'] = content;
    if (dateMarker != null) body['date_marker'] = dateMarker;
    if (scope != null) body['scope'] = scope;
    final data = await _patch(host, '/api/projects/$projectId/annotations/$id/', apiKey, body);
    return Annotation.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteAnnotation(String host, String projectId, String apiKey, int id) async {
    try {
      final response = await _httpClient
          .delete(
            _uri(host, '/api/projects/$projectId/annotations/$id/'),
            headers: _headers(apiKey),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 300) {
        throw PosthogApiError.fromResponse(response.statusCode, response.body);
      }
    } on TimeoutException {
      throw NetworkError('Request timed out');
    } on http.ClientException catch (e) {
      throw NetworkError('Connection failed', cause: e);
    }
  }

  // -- HogQL (SQL Editor) --

  Future<SqlResult> executeHogQL(
    String host, String projectId, String apiKey,
    String query, {
    int limit = 100,
  }) async {
    final data = await _post(
      host,
      '/api/projects/$projectId/query/',
      apiKey,
      {
        'query': {
          'kind': 'HogQLQuery',
          'query': query,
        },
      },
      timeout: const Duration(seconds: 60),
    );
    return SqlResult.fromJson(data as Map<String, dynamic>);
  }

  // -- Actions --

  Future<List<PosthogAction>> fetchActions(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/projects/$projectId/actions/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => PosthogAction.fromJson(j)).toList();
  }

  Future<PosthogAction> fetchAction(String host, String projectId, String apiKey, int id) async {
    final data = await _get(host, '/api/projects/$projectId/actions/$id/', apiKey);
    return PosthogAction.fromJson(data as Map<String, dynamic>);
  }

  // -- Event Definitions --

  Future<List<EventDefinition>> fetchEventDefinitions(
    String host, String projectId, String apiKey, {
    String? search,
    int limit = 100,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _get(host, '/api/projects/$projectId/event_definitions/', apiKey, queryParams: params);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => EventDefinition.fromJson(j)).toList();
  }

  // -- Groups --

  Future<List<GroupType>> fetchGroupTypes(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/projects/$projectId/groups_types/', apiKey);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map((j) => GroupType.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<Group>> fetchGroups(
    String host, String projectId, String apiKey, {
    required int groupTypeIndex,
    String? search,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'group_type_index': groupTypeIndex.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final data = await _get(host, '/api/environments/$projectId/groups/', apiKey, queryParams: params);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => Group.fromJson(j)).toList();
  }

  // -- Early Access Features --

  Future<List<EarlyAccessFeature>> fetchEarlyAccessFeatures(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/projects/$projectId/early_access_feature/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => EarlyAccessFeature.fromJson(j)).toList();
  }

  Future<EarlyAccessFeature> fetchEarlyAccessFeature(String host, String projectId, String apiKey, String id) async {
    final data = await _get(host, '/api/projects/$projectId/early_access_feature/$id/', apiKey);
    return EarlyAccessFeature.fromJson(data as Map<String, dynamic>);
  }

  // -- Product Tours --

  Future<List<ProductTour>> fetchProductTours(String host, String projectId, String apiKey) async {
    final data = await _get(host, '/api/projects/$projectId/product_tours/', apiKey);
    final results = data['results'] as List? ?? [];
    return results.whereType<Map<String, dynamic>>().map((j) => ProductTour.fromJson(j)).toList();
  }

  Future<ProductTour> fetchProductTour(String host, String projectId, String apiKey, String id) async {
    final data = await _get(host, '/api/projects/$projectId/product_tours/$id/', apiKey);
    return ProductTour.fromJson(data as Map<String, dynamic>);
  }

  // -- Logs (HogQL) --

  Future<List<LogEntry>> fetchLogs(
    String host, String projectId, String apiKey, {
    String? search,
    List<String> levels = const ['debug', 'log', 'info', 'warn', 'error'],
    int limit = 100,
  }) async {
    final levelFilter = levels.map((l) => "'$l'").join(', ');
    var query = 'SELECT instance_id, timestamp, level, message FROM log_entries WHERE 1=1';
    query += " AND lower(level) IN ($levelFilter)";
    if (search != null && search.isNotEmpty) {
      final escaped = search.replaceAll("'", "\\'");
      query += " AND (message ILIKE '%$escaped%' OR instance_id ILIKE '%$escaped%')";
    }
    query += ' ORDER BY timestamp DESC LIMIT $limit';

    final data = await _post(
      host,
      '/api/projects/$projectId/query/',
      apiKey,
      {'query': {'kind': 'HogQLQuery', 'query': query}},
      timeout: const Duration(seconds: 30),
    );

    final results = <LogEntry>[];
    final rows = data['results'] as List? ?? [];
    for (final row in rows) {
      if (row is List) results.add(LogEntry.fromHogQLRow(row));
    }
    return results;
  }

  // -- LLM Analytics (HogQL) --

  Future<Map<String, dynamic>> fetchLLMAnalytics(String host, String projectId, String apiKey) async {
    // Query LLM generation events for aggregated metrics
    final data = await _post(
      host,
      '/api/projects/$projectId/query/',
      apiKey,
      {
        'query': {
          'kind': 'HogQLQuery',
          'query': '''
SELECT
  properties.\$ai_model as model,
  count() as total_generations,
  avg(properties.\$ai_latency) as avg_latency,
  sum(properties.\$ai_input_tokens) as total_input_tokens,
  sum(properties.\$ai_output_tokens) as total_output_tokens,
  sum(properties.\$ai_total_cost) as total_cost
FROM events
WHERE event = '\$ai_generation'
  AND timestamp > now() - INTERVAL 7 DAY
GROUP BY model
ORDER BY total_generations DESC
'''
        },
      },
      timeout: const Duration(seconds: 30),
    );
    return data as Map<String, dynamic>;
  }

  // -- Revenue Analytics (HogQL) --

  Future<Map<String, dynamic>> fetchRevenueAnalytics(String host, String projectId, String apiKey) async {
    final data = await _post(
      host,
      '/api/projects/$projectId/query/',
      apiKey,
      {
        'query': {
          'kind': 'HogQLQuery',
          'query': '''
SELECT
  toDate(timestamp) as day,
  count() as order_count,
  sum(toFloat64OrNull(toString(properties.\$revenue))) as revenue,
  avg(toFloat64OrNull(toString(properties.\$revenue))) as avg_order_value,
  uniq(distinct_id) as unique_customers
FROM events
WHERE event IN ('\$purchase', 'purchase', 'order_completed', '\$revenue')
  AND timestamp > now() - INTERVAL 30 DAY
GROUP BY day
ORDER BY day DESC
'''
        },
      },
      timeout: const Duration(seconds: 30),
    );
    return data as Map<String, dynamic>;
  }

  // -- Person Events (for person detail timeline) --

  Future<List<EventItem>> fetchPersonEvents(
    String host, String projectId, String apiKey, String distinctId, {
    int limit = 50,
  }) async {
    final escaped = distinctId.replaceAll("'", "\\'");
    final data = await _post(
      host,
      '/api/projects/$projectId/query/',
      apiKey,
      {
        'query': {
          'kind': 'HogQLQuery',
          'query': "SELECT uuid, event, distinct_id, timestamp, properties "
              "FROM events WHERE distinct_id = '$escaped' "
              "ORDER BY timestamp DESC LIMIT $limit",
        },
      },
    );
    final results = <EventItem>[];
    final rows = data['results'] as List? ?? [];
    for (final row in rows) {
      if (row is List) results.add(EventItem.fromHogQLRow(row));
    }
    return results;
  }

  void dispose() {
    _httpClient.close();
  }
}
