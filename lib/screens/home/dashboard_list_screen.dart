import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/dashboard.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class DashboardListScreen extends StatefulWidget {
  const DashboardListScreen({super.key});

  @override
  State<DashboardListScreen> createState() => _DashboardListScreenState();
}

class _DashboardListScreenState extends State<DashboardListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _tagFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDashboards();
  }

  Future<void> _loadDashboards() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    providers.dashboardState.fetchDashboards(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Dashboard> _filteredDashboards(List<Dashboard> dashboards) {
    var result = List<Dashboard>.from(dashboards);

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((d) {
        return d.name.toLowerCase().contains(query) ||
            (d.description?.toLowerCase().contains(query) ?? false) ||
            d.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    // Filter by tag
    if (_tagFilter != null) {
      result = result.where((d) => d.tags.contains(_tagFilter)).toList();
    }

    // Sort: pinned first, then by last modified
    result.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final aDate = a.lastModifiedAt ?? a.createdAt;
      final bDate = b.lastModifiedAt ?? b.createdAt;
      if (aDate != null && bDate != null) return bDate.compareTo(aDate);
      return 0;
    });

    return result;
  }

  Set<String> _allTags(List<Dashboard> dashboards) {
    final tags = <String>{};
    for (final d in dashboards) {
      tags.addAll(d.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).dashboardState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search dashboards...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Tag filter chips
          SignalBuilder(builder: (context, _) {
            final tags = _allTags(state.dashboards.value);
            if (tags.isEmpty) return const SizedBox.shrink();
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tagFilter = null),
                      child: Chip(
                        label: Text('All', style: TextStyle(fontSize: 12, color: _tagFilter == null ? Colors.white : null, fontWeight: _tagFilter == null ? FontWeight.w600 : FontWeight.normal)),
                        backgroundColor: _tagFilter == null ? Theme.of(context).colorScheme.primary : null,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  for (final tag in tags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _tagFilter = _tagFilter == tag ? null : tag),
                        child: Chip(
                          label: Text(tag, style: TextStyle(fontSize: 12, color: _tagFilter == tag ? Colors.white : null, fontWeight: _tagFilter == tag ? FontWeight.w600 : FontWeight.normal)),
                          backgroundColor: _tagFilter == tag ? Theme.of(context).colorScheme.primary : null,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          // Dashboard list
          Expanded(
            child: SignalBuilder(
              builder: (context, _) {
                if (state.isLoading.value && state.dashboards.value.isEmpty) {
                  return const ShimmerList();
                }
                if (state.error.value != null && state.dashboards.value.isEmpty) {
                  return ErrorView(
                    error: state.error.value!,
                    onRetry: _loadDashboards,
                  );
                }

                final dashboards = _filteredDashboards(state.dashboards.value);

                if (dashboards.isEmpty) {
                  return EmptyState(
                    icon: Icons.dashboard_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'No matching dashboards'
                        : 'No dashboards yet',
                    message: _searchQuery.isEmpty
                        ? 'Create dashboards in PostHog web'
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadDashboards,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dashboards.length,
                    itemBuilder: (context, index) {
                      final dashboard = dashboards[index];
                      return _DashboardCard(
                        dashboard: dashboard,
                        onTap: () => context.goNamed(
                          RouteNames.dashboardDetail,
                          pathParameters: {
                            'dashboardId': dashboard.id.toString(),
                          },
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
  final Dashboard dashboard;
  final VoidCallback onTap;

  const _DashboardCard({required this.dashboard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (dashboard.pinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.push_pin, color: theme.colorScheme.primary, size: 16),
                    ),
                  Expanded(
                    child: Text(
                      dashboard.name,
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${dashboard.tileCount} tiles',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              if (dashboard.description != null && dashboard.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dashboard.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              if (dashboard.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: dashboard.tags.take(5).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
