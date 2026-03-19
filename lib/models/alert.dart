class AlertItem {
  final int id;
  final String name;
  final String status; // firing, ok, snoozed
  final int? insightId;
  final String? insightName;
  final Map<String, dynamic>? threshold;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  AlertItem({required this.id, required this.name, this.status = 'ok', this.insightId, this.insightName, this.threshold, this.createdAt, this.raw = const {}});

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      status: json['state']?.toString() ?? json['status']?.toString() ?? 'ok',
      insightId: (json['insight'] as num?)?.toInt(),
      insightName: json['insight_name']?.toString(),
      threshold: json['threshold'] as Map<String, dynamic>?,
      createdAt: _parseDate(json['created_at']),
      raw: json,
    );
  }

  bool get isFiring => status == 'firing' || status == 'errored';
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
