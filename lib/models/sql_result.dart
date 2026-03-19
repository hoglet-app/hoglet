class SqlResult {
  final List<String> columns;
  final List<String> types;
  final List<List<dynamic>> results;
  final bool hasMore;
  final String? hogql;
  final String? clickhouse;

  SqlResult({
    required this.columns,
    required this.types,
    required this.results,
    this.hasMore = false,
    this.hogql,
    this.clickhouse,
  });

  factory SqlResult.fromJson(Map<String, dynamic> json) {
    final rawColumns = json['columns'] as List? ?? [];
    final rawTypes = json['types'] as List? ?? [];
    final rawResults = json['results'] as List? ?? [];

    return SqlResult(
      columns: rawColumns.map((c) => c?.toString() ?? '').toList(),
      types: rawTypes.map((t) => t?.toString() ?? '').toList(),
      results: rawResults
          .whereType<List>()
          .map((row) => List<dynamic>.from(row))
          .toList(),
      hasMore: json['hasMore'] == true,
      hogql: json['hogql']?.toString(),
      clickhouse: json['clickhouse']?.toString(),
    );
  }

  int get rowCount => results.length;
  int get columnCount => columns.length;
  bool get isEmpty => results.isEmpty;
}
