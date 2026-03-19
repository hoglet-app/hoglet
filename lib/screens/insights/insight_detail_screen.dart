import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../di/providers.dart';
import '../../widgets/chart_renderer.dart';
import '../../widgets/breakdown_legend.dart';
import '../../widgets/error_view.dart';
import '../../widgets/filter_summary.dart';
import '../../widgets/open_in_posthog.dart';
import '../../widgets/shimmer_list.dart';

class InsightDetailScreen extends StatefulWidget {
  final String insightId;

  const InsightDetailScreen({super.key, required this.insightId});

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    final insightId = int.tryParse(widget.insightId);
    if (insightId == null) return;

    providers.insightsState.fetchInsight(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
      insightId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).insightsState;

    return SignalBuilder(
      builder: (context, _) {
        final insight = state.insight.value;
        final isLoading = state.isLoading.value;
        final error = state.error.value;

        return Scaffold(
          appBar: AppBar(
            title: Text(insight?.name ?? 'Insight'),
            actions: [
              OpenInPostHogButton(path: '/insights/${widget.insightId}'),
            ],
          ),
          body: () {
            if (isLoading && insight == null) {
              return const ShimmerList(itemCount: 3);
            }
            if (error != null && insight == null) {
              return ErrorView(error: error, onRetry: _loadInsight);
            }
            if (insight == null) {
              return const Center(child: Text('Insight not found'));
            }

            return RefreshIndicator(
              onRefresh: _loadInsight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + description
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        insight.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (insight.description != null &&
                        insight.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: Text(
                          insight.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ),

                    // Filter/breakdown summary
                    FilterSummary(insight: insight),

                    // Type badge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Chip(
                        label: Text(
                          insight.displayType.name.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Chart
                    ChartRenderer(insight: insight, height: 300),

                    // Legend (for multi-series)
                    if (insight.result != null)
                      BreakdownLegend(series: insight.result!.series),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }(),
        );
      },
    );
  }
}
