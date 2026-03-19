import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/insight.dart';
import '../services/posthog_client.dart';

class InsightsState {
  final insight = Signal<Insight?>(null);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchInsight(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
    int insightId,
  ) async {
    isLoading.value = true;
    error.value = null;
    try {
      insight.value =
          await client.fetchInsight(host, projectId, apiKey, insightId);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    insight.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
