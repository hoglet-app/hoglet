class Experiment {
  final int id;
  final String name;
  final String? description;
  final int? featureFlagId;
  final String? featureFlagKey;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ExperimentVariant> variants;
  final ExperimentResults? results;
  final Map<String, dynamic> raw;

  Experiment({
    required this.id,
    required this.name,
    this.description,
    this.featureFlagId,
    this.featureFlagKey,
    this.startDate,
    this.endDate,
    this.variants = const [],
    this.results,
    this.raw = const {},
  });

  factory Experiment.fromJson(Map<String, dynamic> json) {
    final variants = <ExperimentVariant>[];
    final params = json['parameters'] as Map<String, dynamic>? ?? {};
    final variantsList = params['feature_flag_variants'] as List? ?? [];
    for (final v in variantsList) {
      if (v is Map<String, dynamic>) variants.add(ExperimentVariant.fromJson(v));
    }

    ExperimentResults? results;
    final resultsJson = json['results'] as Map<String, dynamic>?;
    if (resultsJson != null) results = ExperimentResults.fromJson(resultsJson);

    return Experiment(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString(),
      featureFlagId: (json['feature_flag'] as Map<String, dynamic>?)?['id'] as int?,
      featureFlagKey: json['feature_flag_key']?.toString() ?? (json['feature_flag'] as Map<String, dynamic>?)?['key']?.toString(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      variants: variants,
      results: results,
      raw: json,
    );
  }

  bool get isRunning => startDate != null && endDate == null;
  bool get isComplete => endDate != null;
  String get status => isComplete ? 'Complete' : isRunning ? 'Running' : 'Draft';
}

class ExperimentVariant {
  final String key;
  final String? name;
  final int rolloutPercentage;

  ExperimentVariant({required this.key, this.name, this.rolloutPercentage = 0});

  factory ExperimentVariant.fromJson(Map<String, dynamic> json) {
    return ExperimentVariant(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString(),
      rolloutPercentage: (json['rollout_percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExperimentResults {
  final String? significance;
  final Map<String, dynamic> raw;

  ExperimentResults({this.significance, this.raw = const {}});

  factory ExperimentResults.fromJson(Map<String, dynamic> json) {
    return ExperimentResults(
      significance: json['significance_code']?.toString() ?? json['significance']?.toString(),
      raw: json,
    );
  }

  bool get isSignificant => significance == 'significant';
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
