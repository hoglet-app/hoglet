import 'package:flutter_solidart/flutter_solidart.dart';
import '../services/posthog_client.dart';

class WebAnalyticsState {
  final data = Signal<Map<String, dynamic>?>(null);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchWebAnalytics(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { data.value = await client.fetchWebAnalytics(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  void dispose() { data.dispose(); isLoading.dispose(); error.dispose(); }
}
