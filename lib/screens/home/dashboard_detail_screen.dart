import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/dashboard.dart';
import '../../models/insight.dart';
import '../../services/posthog_client.dart';
import '../../services/storage_service.dart';
import '../../state/dashboard_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/loading_states.dart';

class DashboardDetailScreen extends StatefulWidget {
  const DashboardDetailScreen({super.key, required this.dashboardId});

  final int dashboardId;

  @override
  State<DashboardDetailScreen> createState() => _DashboardDetailScreenState();
}

class _DashboardDetailScreenState extends State<DashboardDetailScreen> {
  DashboardState? _dashboardState;
  StorageService? _storage;
  PosthogClient? _client;
  bool _initialized = false;

  final Map<int, Insight> _insights = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _dashboardState = AppProviders.of(context).dashboardState;
      _storage = AppProviders.of(context).storage;
      _client = AppProviders.of(context).client;
      _load();
    }
  }

  Future<void> _load() async {
    final host = await _storage!.read(StorageService.keyHost) ?? '';
    final projectId = await _storage!.read(StorageService.keyProjectId) ?? '';
    final apiKey = await _storage!.read(StorageService.keyApiKey) ?? '';

    await _dashboardState!.fetchDashboard(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
      dashboardId: widget.dashboardId,
    );

    final dashboard = _dashboardState!.selectedDashboard.value;
    if (dashboard != null) {
      await _fetchInsights(
        dashboard: dashboard,
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
    }
  }

  Future<void> _fetchInsights({
    required Dashboard dashboard,
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    if (!mounted) return;
    final tiles = dashboard.tiles.where((t) => t.insightId != null).toList();

    await Future.wait(
      tiles.map((tile) async {
        final id = tile.insightId!;
        if (_insights.containsKey(id)) return;
        try {
          final insight = await _client!.fetchInsight(
            host: host,
            projectId: projectId,
            apiKey: apiKey,
            insightId: id,
          );
          if (mounted) {
            setState(() => _insights[id] = insight);
          }
        } catch (_) {
          // Individual insight failures are silent; tile shows placeholder.
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = _dashboardState;
    if (dashboardState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: SignalBuilder(
          builder: (context, _) {
            final dashboard = dashboardState.selectedDashboard.value;
            return Text(dashboard?.name ?? 'Dashboard');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _insights.clear());
              _load();
            },
          ),
        ],
      ),
      body: SignalBuilder(
        builder: (context, _) {
          final isLoading = dashboardState.isLoadingDetail.value;
          final error = dashboardState.detailError.value;
          final dashboard = dashboardState.selectedDashboard.value;

          if (isLoading) {
            return const ShimmerList();
          }
          if (error != null) {
            return ErrorView(
              error: error,
              onRetry: _load,
            );
          }
          if (dashboard == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final tiles = dashboard.tiles;
          if (tiles.isEmpty) {
            return const EmptyState(
              icon: Icons.bar_chart_outlined,
              title: 'No tiles',
              subtitle: 'Add insights to this dashboard in PostHog.',
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                final tile = tiles[index];
                final insight =
                    tile.insightId != null ? _insights[tile.insightId!] : null;

                if (insight == null) {
                  return _PlaceholderTileCard(
                    tileName: tile.insightName ?? 'Loading…',
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InsightCard(
                    insight: insight,
                    tileName: tile.insightName,
                    onTap: () => context.go(
                      '/home/dashboard/${widget.dashboardId}/insight/${insight.id}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PlaceholderTileCard extends StatelessWidget {
  const _PlaceholderTileCard({required this.tileName});

  final String tileName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE3DED6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B19),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3DED6).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
