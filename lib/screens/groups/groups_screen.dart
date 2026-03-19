import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';
import '../../widgets/property_table.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});
  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTypes();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadTypes() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    await p.groupsState.fetchGroupTypes(p.client, c.host, c.projectId, c.apiKey);
    if (p.groupsState.groupTypes.value.isNotEmpty) {
      _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.groupsState.fetchGroups(p.client, c.host, c.projectId, c.apiKey, search: _searchQuery.isNotEmpty ? _searchQuery : null);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).groupsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoadingTypes.value) return const ShimmerList();
        if (state.error.value != null && state.groupTypes.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _loadTypes);
        if (state.groupTypes.value.isEmpty) {
          return const EmptyState(icon: Icons.groups_outlined, title: 'No group types configured', message: 'Configure group analytics in PostHog settings');
        }

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(hintText: 'Search groups...', prefixIcon: const Icon(Icons.search, size: 20), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); _loadGroups(); }) : null),
                onSubmitted: (v) { setState(() => _searchQuery = v); _loadGroups(); },
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            // Group type selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: state.groupTypes.value.map((gt) {
                  final selected = gt.groupTypeIndex == state.selectedTypeIndex.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        state.selectType(gt.groupTypeIndex);
                        _loadGroups();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? theme.colorScheme.primary : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.12)),
                        ),
                        child: Text(
                          gt.displayNamePlural,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: selected ? Colors.white : theme.colorScheme.onSurface,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Groups list
            Expanded(
              child: SignalBuilder(builder: (context, _) {
                if (state.isLoading.value && state.groups.value.isEmpty) return const ShimmerList();
                if (state.error.value != null && state.groups.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _loadGroups);
                if (state.groups.value.isEmpty) return const EmptyState(icon: Icons.groups_outlined, title: 'No groups found');
                return RefreshIndicator(
                  onRefresh: _loadGroups,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.groups.value.length,
                    itemBuilder: (context, i) {
                      final group = state.groups.value[i];
                      return Card(
                        elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                        child: ExpansionTile(
                          leading: const Icon(Icons.groups, size: 22),
                          title: Text(group.displayName, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(group.groupKey, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontFamily: 'monospace', fontSize: 11)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            if (group.groupProperties.isNotEmpty)
                              PropertyTable(properties: group.groupProperties)
                            else
                              Text('No properties', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }
}
