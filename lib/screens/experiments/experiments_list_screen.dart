import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
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
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.experimentsState.fetchExperiments(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).experimentsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Experiments'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.experiments.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.experiments.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.experiments.value.isEmpty) return const EmptyState(icon: Icons.science_outlined, title: 'No experiments yet');

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.experiments.value.length,
            itemBuilder: (context, i) {
              final exp = state.experiments.value[i];
              final statusColor = exp.isComplete ? Colors.green : exp.isRunning ? Colors.orange : Colors.grey;
              return Card(
                elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                child: ListTile(
                  leading: const Icon(Icons.science, size: 22),
                  title: Text(exp.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text(exp.status, style: TextStyle(color: statusColor.shade700, fontSize: 11, fontWeight: FontWeight.w600))),
                    if (exp.featureFlagKey != null) ...[const SizedBox(width: 8), Text(exp.featureFlagKey!, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 10))],
                  ]),
                  onTap: () => context.pushNamed(RouteNames.experimentDetail, pathParameters: {'experimentId': exp.id.toString()}),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
