class EarlyAccessFeature {
  final String id;
  final String name;
  final String description;
  final String stage; // beta, general-availability, archived
  final String? documentationUrl;
  final int? featureFlagId;
  final String? featureFlagKey;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  EarlyAccessFeature({
    required this.id,
    required this.name,
    this.description = '',
    this.stage = 'beta',
    this.documentationUrl,
    this.featureFlagId,
    this.featureFlagKey,
    this.createdAt,
    this.raw = const {},
  });

  factory EarlyAccessFeature.fromJson(Map<String, dynamic> json) {
    final flag = json['feature_flag'] as Map<String, dynamic>?;
    return EarlyAccessFeature(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      stage: json['stage']?.toString() ?? 'beta',
      documentationUrl: json['documentation_url']?.toString(),
      featureFlagId: (flag?['id'] as num?)?.toInt(),
      featureFlagKey: flag?['key']?.toString(),
      createdAt: _parseDate(json['created_at']),
      raw: json,
    );
  }

  String get stageLabel {
    switch (stage) {
      case 'beta':
        return 'Beta';
      case 'general-availability':
        return 'GA';
      case 'archived':
        return 'Archived';
      default:
        return stage;
    }
  }

  bool get isBeta => stage == 'beta';
  bool get isGA => stage == 'general-availability';
  bool get isArchived => stage == 'archived';
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
