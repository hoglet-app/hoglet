class Annotation {
  final int id;
  final String content;
  final DateTime? dateMarker;
  final String scope; // dashboard_item, dashboard, project, organization
  final String? createdByName;
  final String? createdByEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? dashboardItem; // insight id
  final String? insightName;
  final int? dashboardId;
  final String? dashboardName;
  final String? creationType; // USR, GIT
  final Map<String, dynamic> raw;

  Annotation({
    required this.id,
    required this.content,
    this.dateMarker,
    this.scope = 'project',
    this.createdByName,
    this.createdByEmail,
    this.createdAt,
    this.updatedAt,
    this.dashboardItem,
    this.insightName,
    this.dashboardId,
    this.dashboardName,
    this.creationType,
    this.raw = const {},
  });

  factory Annotation.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    return Annotation(
      id: json['id'] as int,
      content: json['content']?.toString() ?? '',
      dateMarker: _parseDate(json['date_marker']),
      scope: json['scope']?.toString() ?? 'project',
      createdByName: createdBy?['first_name']?.toString(),
      createdByEmail: createdBy?['email']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      dashboardItem: (json['dashboard_item'] as num?)?.toInt(),
      insightName: json['insight_name']?.toString() ?? json['insight_derived_name']?.toString(),
      dashboardId: (json['dashboard_id'] as num?)?.toInt(),
      dashboardName: json['dashboard_name']?.toString(),
      creationType: json['creation_type']?.toString(),
      raw: json,
    );
  }

  String get scopeLabel {
    switch (scope) {
      case 'dashboard_item':
        return 'Insight';
      case 'dashboard':
        return 'Dashboard';
      case 'project':
        return 'Project';
      case 'organization':
        return 'Organization';
      default:
        return scope;
    }
  }

  String get scopeTarget {
    switch (scope) {
      case 'dashboard_item':
        return insightName ?? 'Insight #$dashboardItem';
      case 'dashboard':
        return dashboardName ?? 'Dashboard #$dashboardId';
      default:
        return '';
    }
  }

  String get creatorName => createdByName ?? createdByEmail ?? 'Unknown';
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
