import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/dashboard.dart';
import '../services/posthog_client.dart';

class DashboardState {
  final dashboards = Signal<List<Dashboard>>([]);
  final dashboard = Signal<Dashboard?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchDashboards(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
  ) async {
    isLoading.value = true;
    error.value = null;
    try {
      dashboards.value = await client.fetchDashboards(host, projectId, apiKey);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDashboard(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
    int dashboardId,
  ) async {
    isLoadingDetail.value = true;
    detailError.value = null;
    try {
      dashboard.value =
          await client.fetchDashboard(host, projectId, apiKey, dashboardId);
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void dispose() {
    dashboards.dispose();
    dashboard.dispose();
    isLoading.dispose();
    isLoadingDetail.dispose();
    error.dispose();
    detailError.dispose();
  }
}
