import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/dashboard.dart';
import '../services/posthog_client.dart';

class DashboardState {
  DashboardState({required this.client});

  final PosthogClient client;

  final dashboards = Signal<List<Dashboard>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  final selectedDashboard = Signal<Dashboard?>(null);
  final isLoadingDetail = Signal(false);
  final detailError = Signal<Object?>(null);

  Future<void> fetchDashboards({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await client.fetchDashboards(host: host, projectId: projectId, apiKey: apiKey);
      dashboards.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDashboard({
    required String host,
    required String projectId,
    required String apiKey,
    required int dashboardId,
  }) async {
    isLoadingDetail.value = true;
    detailError.value = null;
    try {
      final result = await client.fetchDashboard(host: host, projectId: projectId, apiKey: apiKey, dashboardId: dashboardId);
      selectedDashboard.value = result;
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void dispose() {
    dashboards.dispose();
    isLoading.dispose();
    error.dispose();
    selectedDashboard.dispose();
    isLoadingDetail.dispose();
    detailError.dispose();
  }
}
