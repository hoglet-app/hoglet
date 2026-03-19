class Dashboard {
  final int id;
  final String name;
  final String? description;
  final bool pinned;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? lastModifiedAt;
  final List<DashboardTile> tiles;
  final Map<String, dynamic> raw;

  Dashboard({
    required this.id,
    required this.name,
    this.description,
    this.pinned = false,
    this.tags = const [],
    this.createdAt,
    this.lastModifiedAt,
    this.tiles = const [],
    this.raw = const {},
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final tiles = <DashboardTile>[];
    final tilesJson = json['tiles'] as List? ?? [];
    for (final tile in tilesJson) {
      if (tile is Map<String, dynamic>) {
        tiles.add(DashboardTile.fromJson(tile));
      }
    }

    return Dashboard(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString(),
      pinned: json['pinned'] == true,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      createdAt: _parseDate(json['created_at']),
      lastModifiedAt: _parseDate(json['last_modified_at']),
      tiles: tiles,
      raw: json,
    );
  }

  int get tileCount => tiles.length;
}

class DashboardTile {
  final int id;
  final int? insightId;
  final String? text;
  final String type; // 'INSIGHT', 'TEXT'
  final Map<String, dynamic> raw;

  DashboardTile({
    required this.id,
    this.insightId,
    this.text,
    required this.type,
    this.raw = const {},
  });

  factory DashboardTile.fromJson(Map<String, dynamic> json) {
    // The insight can be nested as a full object or just an id
    int? insightId;
    final insight = json['insight'];
    if (insight is Map<String, dynamic>) {
      insightId = insight['id'] as int?;
    } else if (insight is int) {
      insightId = insight;
    }

    return DashboardTile(
      id: json['id'] as int,
      insightId: insightId,
      text: json['text']?.toString(),
      type: json['type']?.toString() ?? 'INSIGHT',
      raw: json,
    );
  }

  bool get isInsight => type == 'INSIGHT' && insightId != null;
  bool get isText => type == 'TEXT';
}

DateTime? _parseDate(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
