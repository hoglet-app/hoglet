import 'package:flutter_solidart/flutter_solidart.dart';
import '../services/posthog_client.dart';

class LlmModel {
  final String name;
  final int totalGenerations;
  final double avgLatency;
  final int inputTokens;
  final int outputTokens;
  final double totalCost;

  LlmModel({
    required this.name,
    required this.totalGenerations,
    required this.avgLatency,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCost,
  });

  int get totalTokens => inputTokens + outputTokens;
}

class LlmAnalyticsState {
  final models = Signal<List<LlmModel>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchAnalytics(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try {
      final data = await client.fetchLLMAnalytics(host, projectId, apiKey);
      final rows = data['results'] as List? ?? [];
      models.value = rows.whereType<List>().map((row) {
        return LlmModel(
          name: row.isNotEmpty ? row[0]?.toString() ?? 'Unknown' : 'Unknown',
          totalGenerations: row.length > 1 ? (row[1] as num?)?.toInt() ?? 0 : 0,
          avgLatency: row.length > 2 ? (row[2] as num?)?.toDouble() ?? 0 : 0,
          inputTokens: row.length > 3 ? (row[3] as num?)?.toInt() ?? 0 : 0,
          outputTokens: row.length > 4 ? (row[4] as num?)?.toInt() ?? 0 : 0,
          totalCost: row.length > 5 ? (row[5] as num?)?.toDouble() ?? 0 : 0,
        );
      }).toList();
    }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  void dispose() { models.dispose(); isLoading.dispose(); error.dispose(); }
}
