import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/insight.dart';
import '../../routing/route_names.dart';
import '../../widgets/error_view.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/shimmer_list.dart';

class DashboardDetailScreen extends StatefulWidget {
  final String dashboardId;

  const DashboardDetailScreen({super.key, required this.dashboardId});

  @override
  State<DashboardDetailScreen> createState() => _DashboardDetailScreenState();
}

class _DashboardDetailScreenState extends State<DashboardDetailScreen> {
  final _insights = <int, Insight>{};
  bool _loadingInsights = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    final dashboardId = int.tryParse(widget.dashboardId);
    if (dashboardId == null) return;

    await providers.dashboardState.fetchDashboard(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
      dashboardId,
    );

    // After dashboard loads, fetch insights for each tile
    if (mounted) {
      _loadInsights();
    }
  }

  Future<void> _loadInsights() async {
    final providers = AppProviders.of(context);
    final dashboard = providers.dashboardState.dashboard.value;
    if (dashboard == null) return;

    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    setState(() => _loadingInsights = true);

    final insightTiles = dashboard.tiles.where((t) => t.isInsight).toList();
    final futures = insightTiles.map((tile) async {
      try {
        final insight = await providers.client.fetchInsight(
          credentials.host,
          credentials.projectId,
          credentials.apiKey,
          tile.insightId!,
        );
        if (mounted) {
          setState(() => _insights[tile.insightId!] = insight);
        }
      } catch (_) {
        // Individual insight failures are silent — the tile shows a fallback
      }
    });

    await Future.wait(futures);
    if (mounted) {
      setState(() => _loadingInsights = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).dashboardState;

    return SignalBuilder(
      builder: (context, _) {
        final dashboard = state.dashboard.value;
        final isLoading = state.isLoadingDetail.value;
        final error = state.detailError.value;

        return Scaffold(
          appBar: AppBar(
            title: Text(dashboard?.name ?? 'Dashboard'),
          ),
          body: () {
            if (isLoading && dashboard == null) {
              return const ShimmerList();
            }
            if (error != null && dashboard == null) {
              return ErrorView(error: error, onRetry: _loadDashboard);
            }
            if (dashboard == null) {
              return const Center(child: Text('Dashboard not found'));
            }

            final insightTiles =
                dashboard.tiles.where((t) => t.isInsight).toList();

            if (insightTiles.isEmpty) {
              return const Center(child: Text('No insight tiles'));
            }

            return RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: insightTiles.length,
                itemBuilder: (context, index) {
                  final tile = insightTiles[index];
                  final insight = _insights[tile.insightId];

                  if (insight == null) {
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 160,
                        child: Center(
                          child: _loadingInsights
                              ? const CircularProgressIndicator()
                              : Text(
                                  'Could not load insight',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InsightCard(
                      insight: insight,
                      onTap: () => context.goNamed(
                        RouteNames.insightDetail,
                        pathParameters: {
                          'dashboardId': widget.dashboardId,
                          'insightId': insight.id.toString(),
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }(),
        );
      },
    );
  }
}
