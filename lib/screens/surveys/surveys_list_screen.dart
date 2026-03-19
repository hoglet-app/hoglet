import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
import '../../models/survey.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class SurveysListScreen extends StatefulWidget {
  const SurveysListScreen({super.key});
  @override
  State<SurveysListScreen> createState() => _SurveysListScreenState();
}

class _SurveysListScreenState extends State<SurveysListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.surveysState.fetchSurveys(p.client, c.host, c.projectId, c.apiKey);
  }

  List<Survey> _filtered(List<Survey> surveys) {
    if (_searchQuery.isEmpty) return surveys;
    final q = _searchQuery.toLowerCase();
    return surveys.where((s) => s.name.toLowerCase().contains(q) || (s.description?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).surveysState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Surveys'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search surveys...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoading.value && state.surveys.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.surveys.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
              final surveys = _filtered(state.surveys.value);
              if (surveys.isEmpty) return EmptyState(icon: Icons.assignment_outlined, title: _searchQuery.isNotEmpty ? 'No matching surveys' : 'No surveys yet');

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: surveys.length,
                  itemBuilder: (context, i) {
                    final survey = surveys[i];
                    final statusColor = survey.status == 'active' ? Colors.green
                        : survey.status == 'complete' ? Colors.blue
                        : survey.status == 'archived' ? Colors.grey
                        : Colors.orange;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pushNamed(RouteNames.surveyDetail, pathParameters: {'surveyId': survey.id.toString()}),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(survey.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Text(survey.status[0].toUpperCase() + survey.status.substring(1), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.people, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Text('${survey.responseCount} response${survey.responseCount == 1 ? '' : 's'}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                  const SizedBox(width: 12),
                                  Icon(Icons.quiz, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Text('${survey.questions.length} question${survey.questions.length == 1 ? '' : 's'}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                    child: Text(survey.type, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
