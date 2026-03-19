class FeatureFlag {
  final int id;
  final String key;
  final String? name;
  final bool active;
  final int? rolloutPercentage;
  final List<ReleaseCondition> releaseConditions;
  final List<FlagVariant> variants;
  final bool isMultivariate;
  final List<String> tags;
  final DateTime? createdAt;
  final String? createdByName;
  final bool ensureExperiencesContinuity;
  final Map<String, dynamic> raw;

  FeatureFlag({
    required this.id,
    required this.key,
    this.name,
    required this.active,
    this.rolloutPercentage,
    this.releaseConditions = const [],
    this.variants = const [],
    this.isMultivariate = false,
    this.tags = const [],
    this.createdAt,
    this.createdByName,
    this.ensureExperiencesContinuity = false,
    this.raw = const {},
  });

  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    final conditions = <ReleaseCondition>[];
    final filtersJson = json['filters'] as Map<String, dynamic>? ?? {};
    final groupsJson = filtersJson['groups'] as List? ?? [];

    for (final group in groupsJson) {
      if (group is Map<String, dynamic>) {
        conditions.add(ReleaseCondition.fromJson(group));
      }
    }

    // Extract rollout percentage from first group
    int? rollout;
    if (conditions.isNotEmpty) {
      rollout = conditions.first.rolloutPercentage;
    }

    // Parse multivariate variants
    final variants = <FlagVariant>[];
    final multiVariate = filtersJson['multivariate'] as Map<String, dynamic>?;
    final variantsList = multiVariate?['variants'] as List? ?? [];
    for (final v in variantsList) {
      if (v is Map<String, dynamic>) variants.add(FlagVariant.fromJson(v));
    }

    final createdBy = json['created_by'] as Map<String, dynamic>?;

    return FeatureFlag(
      id: json['id'] as int,
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString(),
      active: json['active'] == true,
      rolloutPercentage: rollout,
      releaseConditions: conditions,
      variants: variants,
      isMultivariate: variants.isNotEmpty,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      createdAt: _parseDate(json['created_at']),
      createdByName: createdBy?['first_name']?.toString(),
      ensureExperiencesContinuity: json['ensure_experience_continuity'] == true,
      raw: json,
    );
  }

  String get displayName => name?.isNotEmpty == true ? name! : key;

  FeatureFlag copyWith({bool? active}) {
    return FeatureFlag(
      id: id,
      key: key,
      name: name,
      active: active ?? this.active,
      rolloutPercentage: rolloutPercentage,
      releaseConditions: releaseConditions,
      variants: variants,
      isMultivariate: isMultivariate,
      tags: tags,
      createdAt: createdAt,
      createdByName: createdByName,
      ensureExperiencesContinuity: ensureExperiencesContinuity,
      raw: raw,
    );
  }
}

class FlagVariant {
  final String key;
  final String? name;
  final int rolloutPercentage;

  FlagVariant({required this.key, this.name, this.rolloutPercentage = 0});

  factory FlagVariant.fromJson(Map<String, dynamic> json) {
    return FlagVariant(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString(),
      rolloutPercentage: (json['rollout_percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReleaseCondition {
  final int? rolloutPercentage;
  final List<PropertyFilter> properties;
  final String? variant;

  ReleaseCondition({
    this.rolloutPercentage,
    this.properties = const [],
    this.variant,
  });

  factory ReleaseCondition.fromJson(Map<String, dynamic> json) {
    final propsJson = json['properties'] as List? ?? [];
    final properties = propsJson
        .whereType<Map<String, dynamic>>()
        .map((p) => PropertyFilter.fromJson(p))
        .toList();

    return ReleaseCondition(
      rolloutPercentage: (json['rollout_percentage'] as num?)?.toInt(),
      properties: properties,
      variant: json['variant']?.toString(),
    );
  }

  String get summary {
    final parts = <String>[];
    if (rolloutPercentage != null) {
      parts.add('$rolloutPercentage% of users');
    }
    for (final prop in properties) {
      parts.add(prop.summary);
    }
    if (parts.isEmpty) return 'All users';
    return parts.join(' AND ');
  }
}

class PropertyFilter {
  final String key;
  final String type; // person, event, group, etc.
  final String operator; // exact, is_not, contains, etc.
  final dynamic value;

  PropertyFilter({
    required this.key,
    required this.type,
    required this.operator,
    this.value,
  });

  factory PropertyFilter.fromJson(Map<String, dynamic> json) {
    return PropertyFilter(
      key: json['key']?.toString() ?? '',
      type: json['type']?.toString() ?? 'person',
      operator: json['operator']?.toString() ?? 'exact',
      value: json['value'],
    );
  }

  String get summary {
    final displayValue = value is List ? (value as List).join(', ') : value?.toString() ?? '';
    return '$key $operator $displayValue';
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
