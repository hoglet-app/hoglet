class Insight {
  Insight({
    required this.id,
    required this.name,
    this.description,
    this.insightType,
    this.queryKind,
    this.result,
    this.filters,
    this.query,
    this.lastRefresh,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final String? insightType;
  final String? queryKind;
  final dynamic result;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? query;
  final DateTime? lastRefresh;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayType {
    // New-style query-based insights
    if (queryKind != null) {
      if (queryKind == 'TrendsQuery') return 'TRENDS';
      if (queryKind == 'FunnelsQuery') return 'FUNNELS';
      if (queryKind == 'LifecycleQuery') return 'LIFECYCLE';
      if (queryKind == 'RetentionQuery') return 'RETENTION';
      if (queryKind == 'PathsQuery') return 'PATHS';
      if (queryKind == 'StickinessQuery') return 'STICKINESS';
    }
    // Legacy filter-based insights
    final legacy = insightType?.toUpperCase();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    // Fallback: try to detect from result shape
    if (result is List && (result as List).isNotEmpty) {
      final first = (result as List).first;
      if (first is Map) {
        if (first.containsKey('aggregated_value')) return 'NUMBER';
        if (first.containsKey('data') && first.containsKey('labels')) return 'TRENDS';
        if (first.containsKey('conversion_rate')) return 'FUNNELS';
      }
    }
    return 'UNKNOWN';
  }

  bool get isSupportedChart {
    final type = displayType;
    return type == 'TRENDS' || type == 'FUNNELS' || type == 'NUMBER';
  }

  factory Insight.fromJson(Map<String, dynamic> json) {
    // Extract the actual query kind — PostHog wraps queries in InsightVizNode
    String? queryKind;
    final query = json['query'] as Map<String, dynamic>?;
    if (query != null) {
      final kind = query['kind'] as String?;
      if (kind == 'InsightVizNode' || kind == 'InsightActorsQueryNode') {
        // Unwrap: the real query is in 'source'
        queryKind = (query['source'] as Map<String, dynamic>?)?['kind'] as String?;
      } else {
        queryKind = kind;
      }
    }

    return Insight(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      insightType: json['filters']?['insight'] as String?,
      queryKind: queryKind,
      result: json['result'],
      filters: json['filters'] as Map<String, dynamic>?,
      query: json['query'] as Map<String, dynamic>?,
      lastRefresh: json['last_refresh'] != null ? DateTime.tryParse(json['last_refresh'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['last_modified_at'] != null ? DateTime.tryParse(json['last_modified_at'].toString()) : null,
    );
  }
}
