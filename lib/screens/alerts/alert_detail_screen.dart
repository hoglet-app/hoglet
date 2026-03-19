import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});
  @override State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  @override void didChangeDependencies() { super.didChangeDependencies(); _load(); }

  Future<void> _load() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    final id = int.tryParse(widget.alertId); if (id == null) return;
    p.alertsState.fetchAlert(p.client, c.host, c.projectId, c.apiKey, id);
  }

  Future<void> _dismiss() async {
    final p = AppProviders.of(context); final c = await p.storage.readCredentials(); if (c == null) return;
    final id = int.tryParse(widget.alertId); if (id == null) return;
    try {
      await p.alertsState.dismissAlert(p.client, c.host, c.projectId, c.apiKey, id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert dismissed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).alertsState;
    final theme = Theme.of(context);
    return SignalBuilder(builder: (context, _) {
      final alert = state.alert.value; final isLoading = state.isLoadingDetail.value; final error = state.detailError.value;
      return Scaffold(
        appBar: AppBar(title: Text(alert?.name ?? 'Alert')),
        body: () {
          if (isLoading && alert == null) return const ShimmerList(itemCount: 3);
          if (error != null && alert == null) return ErrorView(error: error, onRetry: _load);
          if (alert == null) return const Center(child: Text('Alert not found'));
          final statusColor = alert.isFiring ? Colors.red : Colors.green;
          return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(alert.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(alert.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700))),
              if (alert.insightName != null) ...[const SizedBox(height: 12), Text('Linked insight: ${alert.insightName}', style: theme.textTheme.bodyMedium)],
            ]))),
            if (alert.isFiring) ...[const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _dismiss, icon: const Icon(Icons.snooze), label: const Text('Dismiss Alert'))],
          ]));
        }(),
      );
    });
  }
}
