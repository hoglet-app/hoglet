class EventDefinition {
  final String id;
  final String name;
  final String? description;
  final List<String> tags;
  final bool? verified;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;
  final bool isAction;
  final Map<String, dynamic> raw;

  EventDefinition({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    this.verified,
    this.lastSeenAt,
    this.createdAt,
    this.isAction = false,
    this.raw = const {},
  });

  factory EventDefinition.fromJson(Map<String, dynamic> json) {
    return EventDefinition(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      verified: json['verified'] as bool?,
      lastSeenAt: _parseDate(json['last_seen_at']),
      createdAt: _parseDate(json['created_at']),
      isAction: json['is_action'] == true,
      raw: json,
    );
  }

  bool get isPosthogEvent => name.startsWith('\$');
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
