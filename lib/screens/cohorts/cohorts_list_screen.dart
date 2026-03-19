import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/cohort.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    providers.cohortsState.fetchCohorts(providers.client, credentials.host, credentials.projectId, credentials.apiKey);
  }

  List<Cohort> _filtered(List<Cohort> cohorts) {
    if (_searchQuery.isEmpty) return cohorts;
    final q = _searchQuery.toLowerCase();
    return cohorts.where((c) => c.name.toLowerCase().contains(q) || (c.description?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).cohortsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cohorts'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cohorts...',
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
              if (state.isLoading.value && state.cohorts.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.cohorts.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
              final cohorts = _filtered(state.cohorts.value);
              if (cohorts.isEmpty) return EmptyState(icon: Icons.people_outlined, title: _searchQuery.isNotEmpty ? 'No matching cohorts' : 'No cohorts yet', message: _searchQuery.isEmpty ? 'Create cohorts in PostHog web' : null);

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cohorts.length,
                  itemBuilder: (context, index) {
                    final cohort = cohorts[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pushNamed(RouteNames.cohortDetail, pathParameters: {'cohortId': cohort.id.toString()}),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.people, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cohort.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text('${cohort.count} persons', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: (cohort.isStatic ? Colors.grey : Colors.blue).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(cohort.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cohort.isStatic ? Colors.grey : Colors.blue)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
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
