import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/insight.dart';
import '../services/posthog_client.dart';

class InsightsState {
  InsightsState({required this.client});

  final PosthogClient client;

  final selectedInsight = Signal<Insight?>(null);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchInsight({
    required String host,
    required String projectId,
    required String apiKey,
    required int insightId,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await client.fetchInsight(host: host, projectId: projectId, apiKey: apiKey, insightId: insightId);
      selectedInsight.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    selectedInsight.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
