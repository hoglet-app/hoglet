import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});
  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _propertyType = 'event';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
    _loadProperties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.dataManagementState.fetchEventDefinitions(p.client, c.host, c.projectId, c.apiKey, search: _searchController.text.isEmpty ? null : _searchController.text);
  }

  Future<void> _loadProperties() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.dataManagementState.fetchPropertyDefinitions(p.client, c.host, c.projectId, c.apiKey, type: _propertyType);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).dataManagementState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Management'),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Events'), Tab(text: 'Properties')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(state, theme),
          _buildPropertiesTab(state, theme),
        ],
      ),
    );
  }

  Widget _buildEventsTab(dynamic state, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _loadEvents(); })
                  : null,
            ),
            onSubmitted: (_) => _loadEvents(),
          ),
        ),
        Expanded(
          child: SignalBuilder(builder: (context, _) {
            if (state.isLoadingEvents.value && state.eventDefinitions.value.isEmpty) return const ShimmerList();
            if (state.error.value != null && state.eventDefinitions.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _loadEvents);
            if (state.eventDefinitions.value.isEmpty) return const EmptyState(icon: Icons.bolt_outlined, title: 'No event definitions');
            return RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.eventDefinitions.value.length,
                itemBuilder: (context, i) {
                  final event = state.eventDefinitions.value[i];
                  return Card(
                    elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                    child: ListTile(
                      leading: Icon(
                        event.isPosthogEvent ? Icons.analytics : (event.isAction ? Icons.touch_app : Icons.bolt),
                        size: 20,
                        color: event.isPosthogEvent ? Colors.blue : theme.colorScheme.primary,
                      ),
                      title: Text(event.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: event.lastSeenAt != null
                          ? Text('Last seen: ${_formatDate(event.lastSeenAt!)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))
                          : null,
                      trailing: event.verified == true ? Icon(Icons.verified, size: 16, color: Colors.green.shade600) : null,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPropertiesTab(dynamic state, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _PropertyTypeChip(label: 'Event', selected: _propertyType == 'event', onTap: () { setState(() => _propertyType = 'event'); _loadProperties(); }),
              const SizedBox(width: 8),
              _PropertyTypeChip(label: 'Person', selected: _propertyType == 'person', onTap: () { setState(() => _propertyType = 'person'); _loadProperties(); }),
              const SizedBox(width: 8),
              _PropertyTypeChip(label: 'Session', selected: _propertyType == 'session', onTap: () { setState(() => _propertyType = 'session'); _loadProperties(); }),
            ],
          ),
        ),
        Expanded(
          child: SignalBuilder(builder: (context, _) {
            if (state.isLoadingProperties.value && state.propertyDefinitions.value.isEmpty) return const ShimmerList();
            if (state.error.value != null && state.propertyDefinitions.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _loadProperties);
            final props = state.propertyDefinitions.value as List<Map<String, dynamic>>;
            if (props.isEmpty) return const EmptyState(icon: Icons.list_alt_outlined, title: 'No property definitions');
            return RefreshIndicator(
              onRefresh: _loadProperties,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: props.length,
                itemBuilder: (context, i) {
                  final prop = props[i];
                  final name = prop['name']?.toString() ?? '';
                  final propType = prop['property_type']?.toString();
                  return Card(
                    elevation: 0, margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                    child: ListTile(
                      leading: const Icon(Icons.data_object, size: 20),
                      title: Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: propType != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(propType, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                            )
                          : null,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _PropertyTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PropertyTypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: selected ? Colors.white : theme.colorScheme.onSurface, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
        ),
      ),
    );
  }
}
