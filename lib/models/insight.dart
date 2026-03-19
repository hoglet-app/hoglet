enum InsightDisplayType {
  trends,
  funnels,
  number,
  retention,
  lifecycle,
  paths,
  stickiness,
  unknown,
}

class Insight {
  final int id;
  final String name;
  final String? description;
  final InsightDisplayType displayType;
  final String chartDisplay; // ActionsLineGraph, ActionsPie, ActionsBar, ActionsTable, BoldNumber, etc.
  final InsightResult? result;
  final Map<String, dynamic>? filters;
  final Map<String, dynamic>? query;
  final Map<String, dynamic> raw;

  Insight({
    required this.id,
    required this.name,
    this.description,
    required this.displayType,
    this.chartDisplay = 'ActionsLineGraph',
    this.result,
    this.filters,
    this.query,
    this.raw = const {},
  });

  bool get isPie => chartDisplay == 'ActionsPie';
  bool get isBar => chartDisplay == 'ActionsBar' || chartDisplay == 'ActionsBarValue';
  bool get isTable => chartDisplay == 'ActionsTable';
  bool get isWorldMap => chartDisplay == 'WorldMap';

  factory Insight.fromJson(Map<String, dynamic> json) {
    final displayType = _detectDisplayType(json);
    final chartDisplay = _detectChartDisplay(json);

    // Unwrap InsightVizNode if present
    var resultData = json['result'];
    final queryNode = json['query'];
    if (queryNode is Map<String, dynamic> &&
        queryNode['kind'] == 'InsightVizNode') {
      final source = queryNode['source'];
      if (source is Map<String, dynamic>) {
        // Result may be nested under the source kind
      }
    }

    return Insight(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString(),
      displayType: displayType,
      chartDisplay: chartDisplay,
      result: resultData != null
          ? InsightResult.parse(resultData, displayType)
          : null,
      filters: json['filters'] as Map<String, dynamic>?,
      query: json['query'] as Map<String, dynamic>?,
      raw: json,
    );
  }

  bool get isSupportedChart =>
      displayType == InsightDisplayType.trends ||
      displayType == InsightDisplayType.funnels ||
      displayType == InsightDisplayType.number ||
      displayType == InsightDisplayType.retention ||
      displayType == InsightDisplayType.lifecycle ||
      displayType == InsightDisplayType.stickiness;
}

class InsightResult {
  final List<InsightSeries> series;
  final List<FunnelStep>? funnelSteps;
  final double? numberValue;
  final double? previousValue;

  InsightResult({
    this.series = const [],
    this.funnelSteps,
    this.numberValue,
    this.previousValue,
  });

  factory InsightResult.parse(dynamic data, InsightDisplayType type) {
    switch (type) {
      case InsightDisplayType.trends:
      case InsightDisplayType.lifecycle:
      case InsightDisplayType.stickiness:
        return _parseTrendsSeries(data);
      case InsightDisplayType.funnels:
        return _parseFunnels(data);
      case InsightDisplayType.number:
        return _parseNumber(data);
      default:
        return InsightResult();
    }
  }

  static InsightResult _parseTrendsSeries(dynamic data) {
    final series = <InsightSeries>[];

    if (data is List) {
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        if (item is Map<String, dynamic>) {
          series.add(InsightSeries.fromTrendResult(item, i));
        }
      }
    }

    return InsightResult(series: series);
  }

  static InsightResult _parseFunnels(dynamic data) {
    final steps = <FunnelStep>[];

    // Funnels can be a list of steps or a list of lists (breakdown)
    if (data is List && data.isNotEmpty) {
      if (data.first is List) {
        // Breakdown funnels — use first breakdown for now
        final firstBreakdown = data.first as List;
        for (final step in firstBreakdown) {
          if (step is Map<String, dynamic>) {
            steps.add(FunnelStep.fromJson(step));
          }
        }
      } else {
        // Simple funnel
        for (final step in data) {
          if (step is Map<String, dynamic>) {
            steps.add(FunnelStep.fromJson(step));
          }
        }
      }
    }

    return InsightResult(funnelSteps: steps);
  }

  static InsightResult _parseNumber(dynamic data) {
    double? value;
    double? previous;

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        final aggregatedValue = first['aggregated_value'];
        if (aggregatedValue is num) {
          value = aggregatedValue.toDouble();
        }
        // Check for data list to get the value
        final dataList = first['data'] as List?;
        if (value == null && dataList != null && dataList.isNotEmpty) {
          final lastVal = dataList.last;
          if (lastVal is num) value = lastVal.toDouble();
        }
      }
    } else if (data is num) {
      value = data.toDouble();
    }

    return InsightResult(numberValue: value, previousValue: previous);
  }
}

class InsightSeries {
  final String label;
  final List<double> values;
  final List<String> labels;
  final List<DateTime>? timestamps;
  final String? breakdownValue;
  final int colorIndex;

  InsightSeries({
    required this.label,
    required this.values,
    this.labels = const [],
    this.timestamps,
    this.breakdownValue,
    this.colorIndex = 0,
  });

  factory InsightSeries.fromTrendResult(Map<String, dynamic> json, int index) {
    final dataRaw = json['data'] as List? ?? [];
    final values = dataRaw.map((v) => (v as num?)?.toDouble() ?? 0.0).toList();

    final labelsRaw = json['labels'] as List? ?? [];
    final labels = labelsRaw.map((l) => l?.toString() ?? '').toList();

    final daysRaw = json['days'] as List? ?? [];
    final timestamps = daysRaw
        .map((d) => DateTime.tryParse(d?.toString() ?? ''))
        .whereType<DateTime>()
        .toList();

    // Build a descriptive label
    final action = json['action'] as Map<String, dynamic>?;
    final actionName = action?['name']?.toString() ?? json['label']?.toString() ?? 'Series ${index + 1}';
    final breakdownValue = json['breakdown_value']?.toString();
    final label = breakdownValue != null && breakdownValue != 'all'
        ? '$actionName — $breakdownValue'
        : actionName;

    return InsightSeries(
      label: label,
      values: values,
      labels: labels,
      timestamps: timestamps.isEmpty ? null : timestamps,
      breakdownValue: breakdownValue,
      colorIndex: index,
    );
  }
}

class FunnelStep {
  final String name;
  final int order;
  final int count;
  final double conversionRate;
  final double? dropOffRate;
  final String? breakdownValue;

  FunnelStep({
    required this.name,
    required this.order,
    required this.count,
    required this.conversionRate,
    this.dropOffRate,
    this.breakdownValue,
  });

  factory FunnelStep.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ??
        json['custom_name']?.toString() ??
        json['action_id']?.toString() ??
        'Step';
    final conversionRate = (json['conversion_rate'] as num?)?.toDouble() ??
        (json['conversionRate'] as num?)?.toDouble() ??
        0.0;

    return FunnelStep(
      name: name,
      order: (json['order'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      conversionRate: conversionRate,
      dropOffRate: (json['droppedOffRate'] as num?)?.toDouble() ??
          (json['dropped_off_rate'] as num?)?.toDouble(),
      breakdownValue: json['breakdown_value']?.toString(),
    );
  }
}

InsightDisplayType _detectDisplayType(Map<String, dynamic> json) {
  // 1. Check modern query.source.kind
  final query = json['query'] as Map<String, dynamic>?;
  if (query != null) {
    final source = query['source'] as Map<String, dynamic>? ?? query;
    final kind = source['kind']?.toString();
    if (kind != null) {
      return _kindToType(kind);
    }
  }

  // 2. Check legacy filters.insight
  final filters = json['filters'] as Map<String, dynamic>?;
  if (filters != null) {
    final insight = filters['insight']?.toString().toUpperCase();
    if (insight != null) {
      return _insightStringToType(insight);
    }
    final displayType = filters['display']?.toString();
    if (displayType == 'BoldNumber' || displayType == 'ActionsLineGraph') {
      return displayType == 'BoldNumber'
          ? InsightDisplayType.number
          : InsightDisplayType.trends;
    }
  }

  // 3. Infer from result shape
  final result = json['result'];
  if (result is List && result.isNotEmpty) {
    final first = result.first;
    if (first is Map<String, dynamic>) {
      if (first.containsKey('aggregated_value')) return InsightDisplayType.number;
      if (first.containsKey('data') && first.containsKey('labels')) {
        return InsightDisplayType.trends;
      }
      if (first.containsKey('conversion_rate') || first.containsKey('order')) {
        return InsightDisplayType.funnels;
      }
    }
  }

  return InsightDisplayType.unknown;
}

InsightDisplayType _kindToType(String kind) {
  switch (kind) {
    case 'TrendsQuery':
      return InsightDisplayType.trends;
    case 'FunnelsQuery':
      return InsightDisplayType.funnels;
    case 'RetentionQuery':
      return InsightDisplayType.retention;
    case 'PathsQuery':
      return InsightDisplayType.paths;
    case 'StickinessQuery':
      return InsightDisplayType.stickiness;
    case 'LifecycleQuery':
      return InsightDisplayType.lifecycle;
    default:
      return InsightDisplayType.unknown;
  }
}

String _detectChartDisplay(Map<String, dynamic> json) {
  // Check query.source.trendsFilter.display or query.source.display
  final query = json['query'] as Map<String, dynamic>?;
  if (query != null) {
    final source = query['source'] as Map<String, dynamic>? ?? query;
    final trendsFilter = source['trendsFilter'] as Map<String, dynamic>?;
    if (trendsFilter != null) {
      final display = trendsFilter['display']?.toString();
      if (display != null) return display;
    }
    final display = source['display']?.toString();
    if (display != null) return display;
  }

  // Check legacy filters.display
  final filters = json['filters'] as Map<String, dynamic>?;
  if (filters != null) {
    final display = filters['display']?.toString();
    if (display != null) return display;
  }

  return 'ActionsLineGraph';
}

InsightDisplayType _insightStringToType(String insight) {
  switch (insight) {
    case 'TRENDS':
      return InsightDisplayType.trends;
    case 'FUNNELS':
      return InsightDisplayType.funnels;
    case 'RETENTION':
      return InsightDisplayType.retention;
    case 'PATHS':
      return InsightDisplayType.paths;
    case 'STICKINESS':
      return InsightDisplayType.stickiness;
    case 'LIFECYCLE':
      return InsightDisplayType.lifecycle;
    default:
      return InsightDisplayType.unknown;
  }
}
