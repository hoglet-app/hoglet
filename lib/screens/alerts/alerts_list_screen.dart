import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
import '../../models/alert.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});
  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.alertsState.fetchAlerts(p.client, c.host, c.projectId, c.apiKey);
  }

  List<AlertItem> _filtered(List<AlertItem> alerts) {
    var result = alerts;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((a) => a.name.toLowerCase().contains(q) || (a.insightName?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_statusFilter == 'firing') {
      result = result.where((a) => a.isFiring).toList();
    } else if (_statusFilter == 'ok') {
      result = result.where((a) => !a.isFiring && a.status != 'snoozed').toList();
    } else if (_statusFilter == 'snoozed') {
      result = result.where((a) => a.status == 'snoozed').toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).alertsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts'), leading: const BackButton()),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search alerts...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                for (final entry in {'all': 'All', 'firing': 'Firing', 'ok': 'OK', 'snoozed': 'Snoozed'}.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _statusFilter = entry.key),
                      child: Chip(
                        label: Text(entry.value, style: TextStyle(fontSize: 12, color: _statusFilter == entry.key ? Colors.white : null, fontWeight: _statusFilter == entry.key ? FontWeight.w600 : FontWeight.normal)),
                        backgroundColor: _statusFilter == entry.key ? theme.colorScheme.primary : null,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SignalBuilder(builder: (context, _) {
              if (state.isLoading.value && state.alerts.value.isEmpty) return const ShimmerList();
              if (state.error.value != null && state.alerts.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
              final alerts = _filtered(state.alerts.value);
              if (alerts.isEmpty) return EmptyState(icon: Icons.notifications_outlined, title: _searchQuery.isNotEmpty ? 'No matching alerts' : 'No alerts configured');

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: alerts.length,
                  itemBuilder: (context, i) {
                    final alert = alerts[i];
                    final statusColor = alert.isFiring ? Colors.red : alert.status == 'snoozed' ? Colors.orange : Colors.green;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pushNamed(RouteNames.alertDetail, pathParameters: {'alertId': alert.id.toString()}),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                alert.isFiring ? Icons.warning : alert.status == 'snoozed' ? Icons.snooze : Icons.check_circle,
                                color: statusColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(alert.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text(alert.status[0].toUpperCase() + alert.status.substring(1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                                        ),
                                        if (alert.insightName != null) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(alert.insightName!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
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
}
