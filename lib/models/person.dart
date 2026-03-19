class Person {
  final int id;
  final String? uuid;
  final List<String> distinctIds;
  final Map<String, dynamic> properties;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  Person({
    required this.id,
    this.uuid,
    this.distinctIds = const [],
    this.properties = const {},
    this.createdAt,
    this.raw = const {},
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    final distinctIds = <String>[];
    final ids = json['distinct_ids'] as List? ?? [];
    for (final id in ids) {
      if (id != null) distinctIds.add(id.toString());
    }

    return Person(
      id: json['id'] as int,
      uuid: json['uuid']?.toString(),
      distinctIds: distinctIds,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      createdAt: _parseDate(json['created_at']),
      raw: json,
    );
  }

  String get displayName {
    final email = properties['email']?.toString();
    if (email != null && email.isNotEmpty) return email;
    final name = properties['name']?.toString();
    if (name != null && name.isNotEmpty) return name;
    if (distinctIds.isNotEmpty) return distinctIds.first;
    return 'Anonymous';
  }

  String? get email => properties['email']?.toString();
  String? get name => properties['name']?.toString();
  String get initial => displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}

DateTime? _parseDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}
