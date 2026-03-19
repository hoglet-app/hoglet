import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../models/feature_flag.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/status_badge.dart';

class FlagsListScreen extends StatefulWidget {
  const FlagsListScreen({super.key});

  @override
  State<FlagsListScreen> createState() => _FlagsListScreenState();
}

class _FlagsListScreenState extends State<FlagsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, inactive

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    providers.flagsState.fetchFlags(
      providers.client,
      credentials.host,
      credentials.projectId,
      credentials.apiKey,
    );
  }

  Future<void> _toggleFlag(FeatureFlag flag) async {
    HapticFeedback.mediumImpact();
    final providers = AppProviders.of(context);
    final credentials = await providers.storage.readCredentials();
    if (credentials == null) return;

    try {
      await providers.flagsState.toggleFlag(
        providers.client,
        credentials.host,
        credentials.projectId,
        credentials.apiKey,
        flag.id,
        !flag.active,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flag: $e')),
        );
      }
    }
  }

  List<FeatureFlag> _filteredFlags(List<FeatureFlag> flags) {
    var result = flags;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((f) {
        return f.key.toLowerCase().contains(query) ||
            (f.name?.toLowerCase().contains(query) ?? false) ||
            f.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }
    if (_statusFilter == 'active') {
      result = result.where((f) => f.active).toList();
    } else if (_statusFilter == 'inactive') {
      result = result.where((f) => !f.active).toList();
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
    final state = AppProviders.of(context).flagsState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search flags...',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final entry in {'all': 'All', 'active': 'Active', 'inactive': 'Inactive'}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = entry.key),
                      child: Chip(
                        label: Text(entry.value, style: TextStyle(fontSize: 12, color: _statusFilter == entry.key ? Colors.white : null, fontWeight: _statusFilter == entry.key ? FontWeight.w600 : FontWeight.normal)),
                        backgroundColor: _statusFilter == entry.key ? Theme.of(context).colorScheme.primary : null,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SignalBuilder(
              builder: (context, _) {
                if (state.isLoading.value && state.flags.value.isEmpty) {
                  return const ShimmerList();
                }
                if (state.error.value != null && state.flags.value.isEmpty) {
                  return ErrorView(
                    error: state.error.value!,
                    onRetry: _loadFlags,
                  );
                }

                final flags = _filteredFlags(state.flags.value);

                if (flags.isEmpty) {
                  return EmptyState(
                    icon: Icons.flag_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'No matching flags'
                        : 'No feature flags yet',
                    message: _searchQuery.isEmpty
                        ? 'Create feature flags in PostHog web'
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadFlags,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: flags.length,
                    itemBuilder: (context, index) {
                      final flag = flags[index];
                      return _FlagCard(
                        flag: flag,
                        onTap: () => context.goNamed(
                          RouteNames.flagDetail,
                          pathParameters: {'flagId': flag.id.toString()},
                        ),
                        onToggle: () => _toggleFlag(flag),
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

class _FlagCard extends StatelessWidget {
  final FeatureFlag flag;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _FlagCard({
    required this.flag,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardTheme.color ?? Colors.white,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      flag.key,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Switch.adaptive(
                    value: flag.active,
                    onChanged: (_) => onToggle(),
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              Row(
                children: [
                  StatusBadge(active: flag.active),
                  if (flag.rolloutPercentage != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${flag.rolloutPercentage}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  if (flag.isMultivariate) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Multi', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.purple)),
                    ),
                  ],
                ],
              ),
              if (flag.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: flag.tags.take(4).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
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
