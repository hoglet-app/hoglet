import 'package:flutter_solidart/flutter_solidart.dart';
import '../services/posthog_client.dart';

class WebAnalyticsState {
  final data = Signal<Map<String, dynamic>?>(null);
  final topPages = Signal<List<List<dynamic>>>([]);
  final topReferrers = Signal<List<List<dynamic>>>([]);
  final topBrowsers = Signal<List<List<dynamic>>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchWebAnalytics(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try {
      data.value = await client.fetchWebAnalytics(host, projectId, apiKey);
    }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchDetails(PosthogClient client, String host, String projectId, String apiKey) async {
    try {
      final results = await Future.wait([
        client.fetchTopPages(host, projectId, apiKey),
        client.fetchTopReferrers(host, projectId, apiKey),
        client.fetchTopBrowsers(host, projectId, apiKey),
      ]);
      topPages.value = results[0];
      topReferrers.value = results[1];
      topBrowsers.value = results[2];
    } catch (_) {
      // Non-critical — main metrics already loaded
    }
  }

  void dispose() { data.dispose(); topPages.dispose(); topReferrers.dispose(); topBrowsers.dispose(); isLoading.dispose(); error.dispose(); }
}
