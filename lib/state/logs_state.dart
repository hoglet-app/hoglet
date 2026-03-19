import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/log_entry.dart';
import '../services/posthog_client.dart';

class LogsState {
  final logs = Signal<List<LogEntry>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);
  final selectedLevels = Signal<List<String>>(['debug', 'log', 'info', 'warn', 'error']);

  Future<void> fetchLogs(PosthogClient client, String host, String projectId, String apiKey, {String? search}) async {
    isLoading.value = true; error.value = null;
    try { logs.value = await client.fetchLogs(host, projectId, apiKey, search: search, levels: selectedLevels.value); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  void toggleLevel(String level) {
    final current = List<String>.from(selectedLevels.value);
    if (current.contains(level)) {
      current.remove(level);
    } else {
      current.add(level);
    }
    selectedLevels.value = current;
  }

  void dispose() { logs.dispose(); isLoading.dispose(); error.dispose(); selectedLevels.dispose(); }
}
