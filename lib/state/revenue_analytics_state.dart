import 'package:flutter_solidart/flutter_solidart.dart';
import '../services/posthog_client.dart';

class RevenueDay {
  final String date;
  final int orderCount;
  final double revenue;
  final double avgOrderValue;
  final int uniqueCustomers;

  RevenueDay({
    required this.date,
    required this.orderCount,
    required this.revenue,
    required this.avgOrderValue,
    required this.uniqueCustomers,
  });
}

class RevenueAnalyticsState {
  final days = Signal<List<RevenueDay>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchAnalytics(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try {
      final data = await client.fetchRevenueAnalytics(host, projectId, apiKey);
      final rows = data['results'] as List? ?? [];
      days.value = rows.whereType<List>().map((row) {
        return RevenueDay(
          date: row.isNotEmpty ? row[0]?.toString() ?? '' : '',
          orderCount: row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0,
          revenue: row.length > 2 ? (row[2] as num?)?.toDouble() ?? 0 : 0,
          avgOrderValue: row.length > 3 ? (row[3] as num?)?.toDouble() ?? 0 : 0,
          uniqueCustomers: row.length > 4 ? (row[4] as num?)?.toInt() ?? 0 : 0,
        );
      }).toList();
    }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  double get totalRevenue => days.value.fold(0, (sum, d) => sum + d.revenue);
  int get totalOrders => days.value.fold(0, (sum, d) => sum + d.orderCount);
  int get totalCustomers => days.value.fold(0, (sum, d) => sum + d.uniqueCustomers);
  double get overallAvgOrderValue => totalOrders > 0 ? totalRevenue / totalOrders : 0;

  void dispose() { days.dispose(); isLoading.dispose(); error.dispose(); }
}
