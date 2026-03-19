import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import '../../di/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_list.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  const RevenueAnalyticsScreen({super.key});
  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final p = AppProviders.of(context);
    final c = await p.storage.readCredentials();
    if (c == null) return;
    p.revenueAnalyticsState.fetchAnalytics(p.client, c.host, c.projectId, c.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppProviders.of(context).revenueAnalyticsState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Analytics'),
        leading: const BackButton(),
      ),
      body: SignalBuilder(builder: (context, _) {
        if (state.isLoading.value && state.days.value.isEmpty) return const ShimmerList();
        if (state.error.value != null && state.days.value.isEmpty) return ErrorView(error: state.error.value!, onRetry: _load);
        if (state.days.value.isEmpty) {
          return const EmptyState(
            icon: Icons.attach_money,
            title: 'No revenue data',
            message: 'Send \$purchase or order_completed events to see analytics',
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('LAST 30 DAYS', style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
              const SizedBox(height: 8),
              // Summary cards
              Row(
                children: [
                  Expanded(child: _MetricCard(
                    label: 'Revenue',
                    value: '\$${_fmtMoney(state.totalRevenue)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    theme: theme,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricCard(
                    label: 'Orders',
                    value: _fmtNum(state.totalOrders),
                    icon: Icons.shopping_cart,
                    color: theme.colorScheme.primary,
                    theme: theme,
                  )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _MetricCard(
                    label: 'Avg Order',
                    value: '\$${state.overallAvgOrderValue.toStringAsFixed(2)}',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    theme: theme,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _MetricCard(
                    label: 'Customers',
                    value: _fmtNum(state.totalCustomers),
                    icon: Icons.people,
                    color: Colors.purple,
                    theme: theme,
                  )),
                ],
              ),
              const SizedBox(height: 24),
              Text('DAILY BREAKDOWN', style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2, color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
              const SizedBox(height: 8),
              ...state.days.value.map((day) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(day.date, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Text(
                          '\$${_fmtMoney(day.revenue)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade700),
                        ),
                      ),
                      Text(
                        '${day.orderCount} orders',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      }),
    );
  }

  String _fmtMoney(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(2);
  }

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
