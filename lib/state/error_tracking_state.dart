import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/error_group.dart';
import '../services/posthog_client.dart';

class ErrorTrackingState {
  final errors = Signal<List<ErrorGroup>>([]);
  final errorDetail = Signal<ErrorGroup?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchErrors(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { errors.value = await client.fetchErrorGroups(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchError(PosthogClient client, String host, String projectId, String apiKey, String errorId) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { errorDetail.value = await client.fetchErrorGroup(host, projectId, apiKey, errorId); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  void dispose() { errors.dispose(); errorDetail.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
