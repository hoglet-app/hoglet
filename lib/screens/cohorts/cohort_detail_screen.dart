import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class CohortDetailScreen extends StatefulWidget {
  final String cohortId;
  const CohortDetailScreen({super.key, required this.cohortId});

  @override
  State<CohortDetailScreen> createState() => _CohortDetailScreenState();
}

class _CohortDetailScreenState extends State<CohortDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    final id = int.tryParse(widget.cohortId);
    if (id == null) return;
    providers.cohortsState.fetchCohort(providers.client, credentials.host, credentials.projectId, credentials.apiKey, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).cohortsState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final cohort = state.cohort.value;
      final persons = state.cohortPersons.value;
      final isLoading = state.isLoadingDetail.value;
      final error = state.detailError.value;

      return Scaffold(
        appBar: AppBar(title: Text(cohort?.name ?? 'Cohort')),
        body: () {
          if (isLoading && cohort == null) return const ShimmerList(itemCount: 4);
          if (error != null && cohort == null) return ErrorView(error: error, onRetry: _load);
          if (cohort == null) return const Center(child: Text('Cohort not found'));

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0, color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cohort.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Chip(label: Text(cohort.typeLabel)),
                          const SizedBox(width: 8),
                          Text('${cohort.count} persons', style: theme.textTheme.bodyMedium),
                        ]),
                        if (cohort.description != null && cohort.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(cohort.description!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ],
                    ),
                  ),
                ),
                if (persons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('MEMBERS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  ...persons.take(20).map((p) => Card(
                    elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 16, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12), child: Text(p.initial, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary))),
                      title: Text(p.displayName, style: theme.textTheme.bodyMedium),
                    ),
                  )),
                  if (persons.length > 20)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('+ ${persons.length - 20} more', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                    ),
                ],
              ],
            ),
          );
        }(),
      );
    });
  }
}
