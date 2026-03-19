import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
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
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    p.surveysState.fetchSurveys(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).surveysState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Surveys'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.surveys.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.surveys.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.surveys.value.isEmpty) return const EmptyState(icon: Icons.assignment_outlined, title: 'No surveys yet');

        return RefreshIndicator(onRefresh: _load, child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: state.surveys.value.length,
          itemBuilder: (context, i) {
            final survey = state.surveys.value[i];
            return Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
              child: ListTile(
                leading: const Icon(Icons.assignment, size: 22),
                title: Text(survey.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${survey.responseCount} responses · ${survey.status}', style: theme.textTheme.bodySmall),
                onTap: () => context.pushNamed(RouteNames.surveyDetail, pathParameters: {'surveyId': survey.id.toString()}),
              ),
            );
          },
        ));
      }),
    );
  }
}
