class Dashboard {
  Dashboard({
    required this.id,
    required this.name,
    this.description,
    this.pinned = false,
    this.createdAt,
    this.updatedAt,
    this.tiles = const [],
    this.tags = const [],
  });

  final int id;
  final String name;
  final String? description;
  final bool pinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DashboardTile> tiles;
  final List<String> tags;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final tilesJson = json['tiles'] as List? ?? [];
    return Dashboard(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['last_modified_at'] != null ? DateTime.tryParse(json['last_modified_at'].toString()) : null,
      tiles: tilesJson.map((t) => DashboardTile.fromJson(t as Map<String, dynamic>)).toList(),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
    );
  }
}

class DashboardTile {
  DashboardTile({
    required this.id,
    this.insightId,
    this.insightName,
    this.insightType,
    this.lastRefresh,
    this.color,
    this.layoutData,
  });

  final int id;
  final int? insightId;
  final String? insightName;
  final String? insightType;
  final DateTime? lastRefresh;
  final String? color;
  final Map<String, dynamic>? layoutData;

  factory DashboardTile.fromJson(Map<String, dynamic> json) {
    final insight = json['insight'] as Map<String, dynamic>?;
    return DashboardTile(
      id: json['id'] as int,
      insightId: insight?['id'] as int?,
      insightName: insight?['name'] as String?,
      insightType: insight?['query']?['kind'] as String? ?? insight?['filters']?['insight'] as String?,
      lastRefresh: json['last_refresh'] != null ? DateTime.tryParse(json['last_refresh'].toString()) : null,
      color: json['color'] as String?,
      layoutData: json['layouts'] as Map<String, dynamic>?,
    );
  }
}
