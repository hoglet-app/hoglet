import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:go_router/go_router.dart';
import '../../di/providers.dart';
import '../../routing/route_names.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});
  @override State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  @override void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    p.alertsState.fetchAlerts(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).alertsState;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts'), leading: const BackButton()),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.alerts.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.alerts.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.alerts.value.isEmpty) return const EmptyState(icon: Icons.notifications_outlined, title: 'No alerts configured');
        return RefreshIndicator(onRefresh: _load, child: ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: state.alerts.value.length,
          itemBuilder: (context, i) {
            final alert = state.alerts.value[i];
            final statusColor = alert.isFiring ? Colors.red : Colors.green;
            return Card(elevation: 0, color: Colors.white, margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
              child: ListTile(
                leading: Icon(alert.isFiring ? Icons.warning : Icons.check_circle, color: statusColor, size: 22),
                title: Text(alert.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(alert.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                onTap: () => context.pushNamed(RouteNames.alertDetail, pathParameters: {'alertId': alert.id.toString()}),
              ),
            );
          },
        ));
      }),
    );
  }
}
