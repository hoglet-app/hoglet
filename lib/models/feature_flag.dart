class FeatureFlag {
  FeatureFlag({
    required this.id,
    required this.key,
    required this.name,
    required this.active,
    this.rolloutPercentage,
    this.filters,
    this.createdAt,
    this.isSimpleFlag = false,
    this.rollbackConditions = const [],
    this.ensureExperienceContinuity = false,
  });

  final int id;
  final String key;
  final String name;
  final bool active;
  final int? rolloutPercentage;
  final Map<String, dynamic>? filters;
  final DateTime? createdAt;
  final bool isSimpleFlag;
  final List<dynamic> rollbackConditions;
  final bool ensureExperienceContinuity;

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      id: json['id'] as int,
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      rolloutPercentage: json['rollout_percentage'] as int?,
      filters: json['filters'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      isSimpleFlag: json['is_simple_flag'] as bool? ?? false,
      rollbackConditions: json['rollback_conditions'] as List? ?? [],
      ensureExperienceContinuity: json['ensure_experience_continuity'] as bool? ?? false,
    );
  }

  List<Map<String, dynamic>> get releaseConditions {
    final groups = filters?['groups'] as List?;
    if (groups == null) return [];
    return groups.cast<Map<String, dynamic>>();
  }
}
