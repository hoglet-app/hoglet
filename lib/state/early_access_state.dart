import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/early_access_feature.dart';
import '../services/posthog_client.dart';

class EarlyAccessState {
  final features = Signal<List<EarlyAccessFeature>>([]);
  final feature = Signal<EarlyAccessFeature?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchFeatures(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { features.value = await client.fetchEarlyAccessFeatures(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchFeature(PosthogClient client, String host, String projectId, String apiKey, String id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { feature.value = await client.fetchEarlyAccessFeature(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  void dispose() { features.dispose(); feature.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
