import 'package:flutter_solidart/flutter_solidart.dart';
import '../services/posthog_client.dart';

class RecordingsState {
  final recordings = Signal<List<Map<String, dynamic>>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchRecordings(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { recordings.value = await client.fetchSessionRecordings(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  void dispose() { recordings.dispose(); isLoading.dispose(); error.dispose(); }
}
