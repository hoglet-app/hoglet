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
    if (queryKind != null) {
      if (queryKind == 'TrendsQuery') return 'TRENDS';
      if (queryKind == 'FunnelsQuery') return 'FUNNELS';
      if (queryKind == 'LifecycleQuery') return 'LIFECYCLE';
      if (queryKind == 'RetentionQuery') return 'RETENTION';
      if (queryKind == 'PathsQuery') return 'PATHS';
      if (queryKind == 'StickinessQuery') return 'STICKINESS';
    }
    return insightType?.toUpperCase() ?? 'UNKNOWN';
  }

  bool get isSupportedChart {
    final type = displayType;
    return type == 'TRENDS' || type == 'FUNNELS' || type == 'NUMBER';
  }

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      insightType: json['filters']?['insight'] as String?,
      queryKind: json['query']?['kind'] as String?,
      result: json['result'],
      filters: json['filters'] as Map<String, dynamic>?,
      query: json['query'] as Map<String, dynamic>?,
      lastRefresh: json['last_refresh'] != null ? DateTime.tryParse(json['last_refresh'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['last_modified_at'] != null ? DateTime.tryParse(json['last_modified_at'].toString()) : null,
    );
  }
}
