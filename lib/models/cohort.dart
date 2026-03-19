class Cohort {
  final int id;
  final String name;
  final String? description;
  final int count;
  final bool isStatic;
  final DateTime? createdAt;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic> raw;

  Cohort({
    required this.id,
    required this.name,
    this.description,
    this.count = 0,
    this.isStatic = false,
    this.createdAt,
    this.filters,
    this.raw = const {},
  });

  factory Cohort.fromJson(Map<String, dynamic> json) {
    return Cohort(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      isStatic: json['is_static'] == true,
      createdAt: _parseDate(json['created_at']),
      filters: json['filters'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  String get typeLabel => isStatic ? 'Static' : 'Dynamic';
}

DateTime? _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
