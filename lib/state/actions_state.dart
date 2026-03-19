import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/action.dart';
import '../services/posthog_client.dart';

class ActionsState {
  final actions = Signal<List<PosthogAction>>([]);
  final action = Signal<PosthogAction?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchActions(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { actions.value = await client.fetchActions(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchAction(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { action.value = await client.fetchAction(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  void dispose() { actions.dispose(); action.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
