class Survey {
  final int id;
  final String name;
  final String? description;
  final String type;
  final String status; // draft, active, complete
  final int responseCount;
  final DateTime? createdAt;
  final List<SurveyQuestion> questions;
  final Map<String, dynamic> raw;

  Survey({
    required this.id,
    required this.name,
    this.description,
    this.type = 'popover',
    this.status = 'draft',
    this.responseCount = 0,
    this.createdAt,
    this.questions = const [],
    this.raw = const {},
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    final questions = <SurveyQuestion>[];
    final questionsJson = json['questions'] as List? ?? [];
    for (final q in questionsJson) {
      if (q is Map<String, dynamic>) questions.add(SurveyQuestion.fromJson(q));
    }

    return Survey(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Untitled',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'popover',
      status: _determineStatus(json),
      responseCount: (json['responses_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']),
      questions: questions,
      raw: json,
    );
  }

  static String _determineStatus(Map<String, dynamic> json) {
    if (json['archived'] == true) return 'archived';
    final startDate = json['start_date'];
    final endDate = json['end_date'];
    if (endDate != null) return 'complete';
    if (startDate != null) return 'active';
    return 'draft';
  }
}

class SurveyQuestion {
  final String type;
  final String question;
  final List<String>? choices;

  SurveyQuestion({required this.type, required this.question, this.choices});

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List?)?.map((c) => c?.toString() ?? '').toList();
    return SurveyQuestion(
      type: json['type']?.toString() ?? 'open',
      question: json['question']?.toString() ?? '',
      choices: choices,
    );
  }
}

DateTime? _parseDate(dynamic v) => v is String ? DateTime.tryParse(v) : null;
