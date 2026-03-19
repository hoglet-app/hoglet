import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/experiment.dart';
import '../services/posthog_client.dart';

class ExperimentsState {
  final experiments = Signal<List<Experiment>>([]);
  final experiment = Signal<Experiment?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchExperiments(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { experiments.value = await client.fetchExperiments(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchExperiment(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { experiment.value = await client.fetchExperiment(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  void dispose() { experiments.dispose(); experiment.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
