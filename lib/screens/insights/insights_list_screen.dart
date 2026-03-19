import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/insight.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class InsightsListScreen extends StatefulWidget {
  const InsightsListScreen({super.key});

  @override
  State<InsightsListScreen> createState() => _InsightsListScreenState();
}

class _InsightsListScreenState extends State<InsightsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  InsightDisplayType? _typeFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;
    providers.insightsState.fetchInsightsList(providers.client, credentials.host, credentials.projectId, credentials.apiKey);
  }

  List<Insight> _filteredInsights(List<Insight> insights) {
    var result = insights;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((i) => i.name.toLowerCase().contains(q) || (i.description?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_typeFilter != null) {
      result = result.where((i) => i.displayType == _typeFilter).toList();
    }
    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).insightsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(hintText: 'Search insights...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _typeFilter == null, onTap: () => setState(() => _typeFilter = null)),
                for (final type in [InsightDisplayType.trends, InsightDisplayType.funnels, InsightDisplayType.retention, InsightDisplayType.lifecycle, InsightDisplayType.stickiness, InsightDisplayType.number])
                  _FilterChip(label: type.name[0].toUpperCase() + type.name.substring(1), selected: _typeFilter == type, onTap: () => setState(() => _typeFilter = type)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoadingList.value && state.insightsList.value.isEmpty) return const ShimmerList();
              if (state.listError.value != null && state.insightsList.value.isEmpty) return ErrorView(error: state.listError.value!, onRetry: _loadInsights);
              final insights = _filteredInsights(state.insightsList.value);
              if (insights.isEmpty) return const EmptyState(icon: Icons.insights_outlined, title: 'No insights found');

              return RefreshIndicator(
                onRefresh: _loadInsights,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: insights.length,
                  itemBuilder: (context, index) {
                    final insight = insights[index];
                    return Card(
                      elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                      child: ListTile(
                        leading: Icon(_typeIcon(insight.displayType), size: 22),
                        title: Text(insight.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(insight.displayType.name.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 0.5)),
                        onTap: () => context.push('/insights/${insight.id}'),
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

  IconData _typeIcon(InsightDisplayType type) {
    switch (type) {
      case InsightDisplayType.trends: return Icons.show_chart;
      case InsightDisplayType.funnels: return Icons.filter_alt;
      case InsightDisplayType.retention: return Icons.grid_on;
      case InsightDisplayType.lifecycle: return Icons.timeline;
      case InsightDisplayType.stickiness: return Icons.bar_chart;
      case InsightDisplayType.number: return Icons.tag;
      case InsightDisplayType.paths: return Icons.account_tree;
      default: return Icons.insights;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Chip(
          label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : theme.colorScheme.onSurface, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          backgroundColor: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
