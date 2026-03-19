import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/open_in_posthog.dart';
import '../../widgets/shimmer_list.dart';

class SurveyDetailScreen extends StatefulWidget {
  final String surveyId;
  const SurveyDetailScreen({super.key, required this.surveyId});
  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    final id = int.tryParse(widget.surveyId); if (id == null) return;
    p.surveysState.fetchSurvey(p.client, c.host, c.projectId, c.apiKey, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).surveysState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final survey = state.survey.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(survey?.name ?? 'Survey'),
          actions: [
            OpenInPostHogButton(path: '/surveys/${widget.surveyId}'),
          ],
        ),
        body: () {
          if (isLoading && survey == null) return const ShimmerList(itemCount: 4);
          if (error != null && survey == null) return ErrorView(error: error, onRetry: _load);
          if (survey == null) return const Center(child: Text('Survey not found'));

          final statusColor = survey.status == 'active' ? Colors.green
              : survey.status == 'complete' ? Colors.blue
              : survey.status == 'archived' ? Colors.grey
              : Colors.orange;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(survey.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                survey.status[0].toUpperCase() + survey.status.substring(1),
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                survey.type,
                                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Response count
                        Row(
                          children: [
                            Icon(Icons.people, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Text(
                              '${survey.responseCount} response${survey.responseCount == 1 ? '' : 's'}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (survey.description != null && survey.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(survey.description!, style: theme.textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),

                // Questions
                if (survey.questions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'QUESTIONS (${survey.questions.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...survey.questions.asMap().entries.map((e) {
                    final q = e.value;
                    final idx = e.key;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _questionTypeColor(q.type).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _questionTypeLabel(q.type),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _questionTypeColor(q.type)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(q.question, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            if (q.choices != null && q.choices!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...q.choices!.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      q.type == 'single_choice' ? Icons.radio_button_unchecked : Icons.check_box_outline_blank,
                                      size: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(c, style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              )),
                            ],
                            if (q.type == 'open') ...[
                              const SizedBox(height: 8),
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('Free text response', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                                ),
                              ),
                            ],
                            if (q.type == 'rating') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (i) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(Icons.star_border, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                                )),
                              ),
                            ],
                            if (q.type == 'nps') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(11, (i) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    height: 24,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(child: Text('$i', style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)))),
                                  ),
                                )),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }(),
      );
    });
  }

  Color _questionTypeColor(String type) {
    switch (type) {
      case 'open': return Colors.blue;
      case 'single_choice': return Colors.purple;
      case 'multiple_choice': return Colors.teal;
      case 'rating': return Colors.orange;
      case 'nps': return Colors.green;
      case 'link': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  String _questionTypeLabel(String type) {
    switch (type) {
      case 'open': return 'Open text';
      case 'single_choice': return 'Single choice';
      case 'multiple_choice': return 'Multiple choice';
      case 'rating': return 'Rating';
      case 'nps': return 'NPS';
      case 'link': return 'Link';
      default: return type;
    }
  }
}
