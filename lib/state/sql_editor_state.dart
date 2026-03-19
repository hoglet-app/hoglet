import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/sql_result.dart';
import '../services/posthog_client.dart';

class SqlEditorState {
  final result = Signal<SqlResult?>(null);
  final isRunning = Signal(false);
  final error = Signal<Object?>(null);
  final queryHistory = Signal<List<String>>([]);

  Future<void> executeQuery(PosthogClient client, String host, String projectId, String apiKey, String query) async {
    isRunning.value = true; error.value = null; result.value = null;
    try {
      result.value = await client.executeHogQL(host, projectId, apiKey, query);
      // Add to history (dedup, keep last 50)
      final history = List<String>.from(queryHistory.value);
      history.remove(query);
      history.insert(0, query);
      if (history.length > 50) history.removeLast();
      queryHistory.value = history;
    }
    catch (e) { error.value = e; }
    finally { isRunning.value = false; }
  }

  void clearResult() {
    result.value = null;
    error.value = null;
  }

  void dispose() { result.dispose(); isRunning.dispose(); error.dispose(); queryHistory.dispose(); }
}
