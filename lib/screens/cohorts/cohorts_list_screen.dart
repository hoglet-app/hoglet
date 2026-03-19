import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class CohortsListScreen extends StatefulWidget {
  const CohortsListScreen({super.key});

  @override
  State<CohortsListScreen> createState() => _CohortsListScreenState();
}

class _CohortsListScreenState extends State<CohortsListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    providers.cohortsState.fetchCohorts(providers.client, credentials.host, credentials.projectId, credentials.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).cohortsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cohorts'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.cohorts.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.cohorts.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.cohorts.value.isEmpty) return const EmptyState(icon: Icons.people_outlined, title: 'No cohorts yet', message: 'Create cohorts in PostHog web');

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.cohorts.value.length,
            itemBuilder: (context, index) {
              final cohort = state.cohorts.value[index];
              return Card(
                elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                child: ListTile(
                  leading: const Icon(Icons.people, size: 22),
                  title: Text(cohort.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('${cohort.count} persons · ${cohort.typeLabel}', style: theme.textTheme.bodySmall),
                  onTap: () => context.pushNamed(RouteNames.cohortDetail, pathParameters: {'cohortId': cohort.id.toString()}),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
