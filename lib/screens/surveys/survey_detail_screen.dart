import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
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
      final survey = state.survey.value; final isLoading = state.isLoadingDetail.value; final error = state.detailError.value;
      return Scaffold(
        appBar: AppBar(title: Text(survey?.name ?? 'Survey')),
        body: () {
          if (isLoading && survey == null) return const ShimmerList(itemCount: 4);
          if (error != null && survey == null) return ErrorView(error: error, onRetry: _load);
          if (survey == null) return const Center(child: Text('Survey not found'));

          return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(survey.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Chip(label: Text(survey.status)), const SizedBox(width: 8),
                Text('${survey.responseCount} responses', style: theme.textTheme.bodyMedium),
              ]),
              if (survey.description != null && survey.description!.isNotEmpty) ...[const SizedBox(height: 12), Text(survey.description!, style: theme.textTheme.bodyMedium)],
            ]))),
            if (survey.questions.isNotEmpty) ...[const SizedBox(height: 16),
              Text('QUESTIONS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 8),
              ...survey.questions.asMap().entries.map((e) => Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Q${e.key + 1}: ${e.value.question}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Type: ${e.value.type}', style: theme.textTheme.bodySmall),
                  if (e.value.choices != null) ...e.value.choices!.map((c) => Padding(padding: const EdgeInsets.only(left: 12, top: 2), child: Text('• $c', style: theme.textTheme.bodySmall))),
                ]))))],
          ]));
        }(),
      );
    });
  }
}
