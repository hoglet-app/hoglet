class ProductTour {
  final String id;
  final String name;
  final String description;
  final String type; // tour, announcement
  final bool autoLaunch;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final String? createdByName;
  final bool archived;
  final bool hasDraft;
  final int stepCount;
  final Map<String, dynamic> raw;

  ProductTour({
    required this.id,
    required this.name,
    this.description = '',
    this.type = 'tour',
    this.autoLaunch = false,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.createdByName,
    this.archived = false,
    this.hasDraft = false,
    this.stepCount = 0,
    this.raw = const {},
  });

  factory ProductTour.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    final content = json['content'] as Map<String, dynamic>? ?? {};
    final steps = content['steps'] as List? ?? [];
    return ProductTour(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      type: (content['type'] ?? 'tour').toString(),
      autoLaunch: json['auto_launch'] == true,
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      createdAt: _parseDate(json['created_at']),
      createdByName: createdBy?['first_name']?.toString(),
      archived: json['archived'] == true,
      hasDraft: json['has_draft'] == true,
      stepCount: steps.length,
      raw: json,
    );
  }

  String get status {
    if (archived) return 'Archived';
    if (startDate == null) return 'Draft';
    if (endDate != null) return 'Stopped';
    return 'Running';
  }

  bool get isRunning => startDate != null && endDate == null && !archived;
  bool get isDraft => startDate == null && !archived;
  bool get isStopped => endDate != null && !archived;
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
