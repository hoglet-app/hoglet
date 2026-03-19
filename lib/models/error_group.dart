class ErrorGroup {
  final String id;
  final String fingerprint;
  final String? title;
  final int occurrences;
  final int? affectedUsers;
  final String status;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final Map<String, dynamic> raw;

  ErrorGroup({required this.id, required this.fingerprint, this.title, this.occurrences = 0, this.affectedUsers, this.status = 'active', this.firstSeen, this.lastSeen, this.raw = const {}});

  factory ErrorGroup.fromJson(Map<String, dynamic> json) {
    return ErrorGroup(
      id: json['id']?.toString() ?? '',
      fingerprint: json['fingerprint']?.toString() ?? json['value']?.toString() ?? '',
      title: json['title']?.toString() ?? json['value']?.toString(),
      occurrences: (json['occurrences'] as num?)?.toInt() ?? (json['count'] as num?)?.toInt() ?? 0,
      affectedUsers: (json['users'] as num?)?.toInt() ?? (json['unique_users'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'active',
      firstSeen: _parseDate(json['first_seen']),
      lastSeen: _parseDate(json['last_seen']),
      raw: json,
    );
  }
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
