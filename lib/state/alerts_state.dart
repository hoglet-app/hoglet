import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/alert.dart';
import '../services/posthog_client.dart';

class AlertsState {
  final alerts = Signal<List<AlertItem>>([]);
  final alert = Signal<AlertItem?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchAlerts(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { alerts.value = await client.fetchAlerts(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchAlert(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { alert.value = await client.fetchAlert(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  Future<void> dismissAlert(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    try {
      final updated = await client.dismissAlert(host, projectId, apiKey, id);
      alert.value = updated;
      final current = List<AlertItem>.from(alerts.value);
      final idx = current.indexWhere((a) => a.id == id);
      if (idx != -1) { current[idx] = updated; alerts.value = current; }
    } catch (e) { error.value = e; rethrow; }
  }

  void dispose() { alerts.dispose(); alert.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
