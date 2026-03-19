class PosthogAction {
  final int id;
  final String name;
  final String? description;
  final List<String> tags;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? lastCalculatedAt;
  final String? createdByName;
  final List<ActionStep> steps;
  final bool? verified;
  final int? count;
  final Map<String, dynamic> raw;

  PosthogAction({
    required this.id,
    required this.name,
    this.description,
    this.tags = const [],
    this.deleted = false,
    this.createdAt,
    this.lastCalculatedAt,
    this.createdByName,
    this.steps = const [],
    this.verified,
    this.count,
    this.raw = const {},
  });

  factory PosthogAction.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'] as Map<String, dynamic>?;
    final rawSteps = json['steps'] as List? ?? [];
    return PosthogAction(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString(),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      deleted: json['deleted'] == true,
      createdAt: _parseDate(json['created_at']),
      lastCalculatedAt: _parseDate(json['last_calculated_at']),
      createdByName: createdBy?['first_name']?.toString(),
      steps: rawSteps.whereType<Map<String, dynamic>>().map((s) => ActionStep.fromJson(s)).toList(),
      verified: json['verified'] as bool?,
      count: (json['count'] as num?)?.toInt(),
      raw: json,
    );
  }
}

class ActionStep {
  final String? event;
  final String? selector;
  final String? text;
  final String? textMatching;
  final String? href;
  final String? hrefMatching;
  final String? url;
  final String? urlMatching;

  ActionStep({this.event, this.selector, this.text, this.textMatching, this.href, this.hrefMatching, this.url, this.urlMatching});

  factory ActionStep.fromJson(Map<String, dynamic> json) {
    return ActionStep(
      event: json['event']?.toString(),
      selector: json['selector']?.toString(),
      text: json['text']?.toString(),
      textMatching: json['text_matching']?.toString(),
      href: json['href']?.toString(),
      hrefMatching: json['href_matching']?.toString(),
      url: json['url']?.toString(),
      urlMatching: json['url_matching']?.toString(),
    );
  }

  String get summary {
    final parts = <String>[];
    if (event != null) parts.add('Event: $event');
    if (url != null) parts.add('URL ${urlMatching ?? 'contains'}: $url');
    if (selector != null) parts.add('Selector: $selector');
    if (text != null) parts.add('Text ${textMatching ?? 'exact'}: $text');
    if (href != null) parts.add('Href ${hrefMatching ?? 'exact'}: $href');
    return parts.isEmpty ? 'Any event' : parts.join(' • ');
  }
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
