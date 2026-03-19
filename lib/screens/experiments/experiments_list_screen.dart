import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
import '../../models/experiment.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ExperimentsListScreen extends StatefulWidget {
  const ExperimentsListScreen({super.key});
  @override
  State<ExperimentsListScreen> createState() => _ExperimentsListScreenState();
}

class _ExperimentsListScreenState extends State<ExperimentsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.experimentsState.fetchExperiments(p.client, c.host, c.projectId, c.apiKey);
  }

  List<Experiment> _filtered(List<Experiment> experiments) {
    var result = experiments;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) => e.name.toLowerCase().contains(q) || (e.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_statusFilter != 'all') {
      result = result.where((e) => e.status.toLowerCase() == _statusFilter).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).experimentsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Experiments'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search experiments...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                for (final status in ['all', 'draft', 'running', 'complete'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = status),
                      child: Chip(
                        label: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 12, color: _statusFilter == status ? Colors.white : theme.colorScheme.onSurface, fontWeight: _statusFilter == status ? FontWeight.w600 : FontWeight.normal)),
                        backgroundColor: _statusFilter == status ? theme.colorScheme.primary : null,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoading.value && state.experiments.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.experiments.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
              final experiments = _filtered(state.experiments.value);
              if (experiments.isEmpty) return EmptyState(icon: Icons.science_outlined, title: _searchQuery.isNotEmpty ? 'No matching experiments' : 'No experiments yet');

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: experiments.length,
                  itemBuilder: (context, i) {
                    final exp = experiments[i];
                    final statusColor = exp.isComplete ? Colors.green : exp.isRunning ? Colors.orange : Colors.grey;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pushNamed(RouteNames.experimentDetail, pathParameters: {'experimentId': exp.id.toString()}),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(exp.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Text(exp.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (exp.featureFlagKey != null) ...[
                                    Icon(Icons.flag, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                    const SizedBox(width: 4),
                                    Text(exp.featureFlagKey!, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                  ],
                                  if (exp.variants.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Text('${exp.variants.length} variants', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                                  ],
                                  if (exp.results?.isSignificant == true) ...[
                                    const Spacer(),
                                    Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                                  ],
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
