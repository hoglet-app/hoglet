class GroupType {
  final String groupType;
  final int groupTypeIndex;
  final String? nameSingular;
  final String? namePlural;

  GroupType({
    required this.groupType,
    required this.groupTypeIndex,
    this.nameSingular,
    this.namePlural,
  });

  factory GroupType.fromJson(Map<String, dynamic> json) {
    return GroupType(
      groupType: json['group_type']?.toString() ?? '',
      groupTypeIndex: (json['group_type_index'] as num?)?.toInt() ?? 0,
      nameSingular: json['name_singular']?.toString(),
      namePlural: json['name_plural']?.toString(),
    );
  }

  String get displayName => nameSingular ?? groupType;
  String get displayNamePlural => namePlural ?? '${displayName}s';
}

class Group {
  final String groupKey;
  final int groupTypeIndex;
  final Map<String, dynamic> groupProperties;
  final DateTime? createdAt;

  Group({
    required this.groupKey,
    required this.groupTypeIndex,
    this.groupProperties = const {},
    this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupKey: json['group_key']?.toString() ?? '',
      groupTypeIndex: (json['group_type_index'] as num?)?.toInt() ?? 0,
      groupProperties: json['group_properties'] as Map<String, dynamic>? ?? {},
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get displayName {
    return groupProperties['name']?.toString() ?? groupKey;
  }
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
