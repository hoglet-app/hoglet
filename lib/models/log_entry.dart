class LogEntry {
  final String message;
  final String instanceId;
  final String level; // DEBUG, LOG, INFO, WARN, ERROR
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.instanceId,
    required this.level,
    required this.timestamp,
  });

  factory LogEntry.fromHogQLRow(List<dynamic> row) {
    return LogEntry(
      instanceId: row.isNotEmpty ? row[0]?.toString() ?? '' : '',
      timestamp: row.length > 1 ? DateTime.tryParse(row[1]?.toString() ?? '') ?? DateTime.now() : DateTime.now(),
      level: row.length > 2 ? (row[2]?.toString() ?? 'LOG').toUpperCase() : 'LOG',
      message: row.length > 3 ? row[3]?.toString() ?? '' : '',
    );
  }

  bool get isError => level == 'ERROR';
  bool get isWarn => level == 'WARN' || level == 'WARNING';
  bool get isInfo => level == 'INFO' || level == 'LOG';
  bool get isDebug => level == 'DEBUG';

  String get timeStr {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}
