import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;
  const ExperimentDetailScreen({super.key, required this.experimentId});
  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> {
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    final id = int.tryParse(widget.experimentId); if (id == null) return;
    p.experimentsState.fetchExperiment(p.client, c.host, c.projectId, c.apiKey, id);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).experimentsState;
    final theme = Theme.of(context);

    return SignalBuilder(builder: (context, _) {
      final exp = state.experiment.value; final isLoading = state.isLoadingDetail.value; final error = state.detailError.value;
      return Scaffold(
        appBar: AppBar(title: Text(exp?.name ?? 'Experiment')),
        body: () {
          if (isLoading && exp == null) return const ShimmerList(itemCount: 4);
          if (error != null && exp == null) return ErrorView(error: error, onRetry: _load);
          if (exp == null) return const Center(child: Text('Experiment not found'));

          final statusColor = exp.isComplete ? Colors.green : exp.isRunning ? Colors.orange : Colors.grey;
          return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exp.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Text(exp.status, style: TextStyle(color: statusColor.shade700, fontSize: 12, fontWeight: FontWeight.w600))),
                if (exp.results?.isSignificant == true) ...[const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Significant', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)))],
              ]),
              if (exp.description != null && exp.description!.isNotEmpty) ...[const SizedBox(height: 12), Text(exp.description!, style: theme.textTheme.bodyMedium)],
            ]))),
            if (exp.featureFlagKey != null) ...[const SizedBox(height: 16),
              Text('LINKED FLAG', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 4), Text(exp.featureFlagKey!, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'))],
            if (exp.variants.isNotEmpty) ...[const SizedBox(height: 16),
              Text('VARIANTS', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 8),
              ...exp.variants.map((v) => Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(dense: true, title: Text(v.name ?? v.key, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text('${v.rolloutPercentage}% rollout', style: theme.textTheme.bodySmall))))],
          ]));
        }(),
      );
    });
  }
}
