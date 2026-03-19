import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/insight.dart';
import '../../routing/route_names.dart';
import '../../widgets/error_view.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/open_in_posthog.dart';
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
            actions: [
              OpenInPostHogButton(path: '/dashboard/${widget.dashboardId}'),
            ],
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

            final tiles = dashboard.tiles;
            final theme = Theme.of(context);

            if (tiles.isEmpty) {
              return const Center(child: Text('No tiles on this dashboard'));
            }

            // +1 for the header
            final itemCount = tiles.length + 1;

            return RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // Dashboard info header
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (dashboard.description != null && dashboard.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                dashboard.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Icon(Icons.grid_view, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Text(
                                '${tiles.length} tile${tiles.length == 1 ? '' : 's'}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              ),
                              if (dashboard.createdAt != null) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.calendar_today, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                const SizedBox(width: 4),
                                Text(
                                  '${dashboard.createdAt!.year}-${dashboard.createdAt!.month.toString().padLeft(2, '0')}-${dashboard.createdAt!.day.toString().padLeft(2, '0')}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                ),
                              ],
                              if (dashboard.pinned) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.push_pin, size: 13, color: theme.colorScheme.primary),
                                const SizedBox(width: 2),
                                Text('Pinned', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                              ],
                            ],
                          ),
                          if (dashboard.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: dashboard.tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(tag, style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  final tile = tiles[index - 1];

                  // Text tile
                  if (tile.isText) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            tile.text ?? '',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    );
                  }

                  // Insight tile
                  if (!tile.isInsight) return const SizedBox.shrink();

                  final insight = _insights[tile.insightId];
                  if (insight == null) {
                    return Card(
                      elevation: 0,
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
