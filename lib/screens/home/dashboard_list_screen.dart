import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/dashboard.dart';
import '../../services/storage_service.dart';
import '../../state/dashboard_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_states.dart';

class DashboardListScreen extends StatefulWidget {
  const DashboardListScreen({super.key});

  @override
  State<DashboardListScreen> createState() => _DashboardListScreenState();
}

class _DashboardListScreenState extends State<DashboardListScreen> {
  DashboardState? _dashboardState;
  StorageService? _storage;
  bool _initialized = false;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _dashboardState = dashboardStateProvider.of(context);
      _storage = storageServiceProvider.of(context);
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final host = await _storage!.read(StorageService.keyHost) ?? '';
    final projectId = await _storage!.read(StorageService.keyProjectId) ?? '';
    final apiKey = await _storage!.read(StorageService.keyApiKey) ?? '';
    await _dashboardState!.fetchDashboards(
      host: host,
      projectId: projectId,
      apiKey: apiKey,
    );
  }

  List<Dashboard> _sorted(List<Dashboard> dashboards) {
    final q = _searchQuery.toLowerCase().trim();
    final filtered = q.isEmpty
        ? List<Dashboard>.from(dashboards)
        : dashboards
            .where((d) => d.name.toLowerCase().contains(q))
            .toList();

    filtered.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = _dashboardState;
    if (dashboardState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search dashboards…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3DED6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3DED6)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context, _) {
                final isLoading = dashboardState.isLoading.value;
                final error = dashboardState.error.value;

                if (isLoading) {
                  return const ShimmerList();
                }
                if (error != null) {
                  return ErrorView(
                    error: error,
                    onRetry: _load,
                  );
                }

                final dashboards = dashboardState.dashboards.value;
                final sorted = _sorted(dashboards);

                if (sorted.isEmpty) {
                  return EmptyState(
                    icon: Icons.dashboard_outlined,
                    title: _searchQuery.isEmpty
                        ? 'No dashboards yet'
                        : 'No results for "$_searchQuery"',
                    subtitle: _searchQuery.isEmpty
                        ? 'Create a dashboard in PostHog to see it here.'
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final dashboard = sorted[index];
                      return _DashboardCard(
                        dashboard: dashboard,
                        onTap: () => context.go(
                          '/home/dashboard/${dashboard.id}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.dashboard,
    required this.onTap,
  });

  final Dashboard dashboard;
  final VoidCallback onTap;

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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (dashboard.pinned) ...[
                  const Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Color(0xFFF15A24),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dashboard.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1B19),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dashboard.description != null &&
                          dashboard.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          dashboard.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F6A63),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '${dashboard.tiles.length} tile${dashboard.tiles.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9890),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9E9890),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
