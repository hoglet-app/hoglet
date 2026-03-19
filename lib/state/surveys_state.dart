import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/survey.dart';
import '../services/posthog_client.dart';

class SurveysState {
  final surveys = Signal<List<Survey>>([]);
  final survey = Signal<Survey?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchSurveys(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { surveys.value = await client.fetchSurveys(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchSurvey(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { survey.value = await client.fetchSurvey(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  void dispose() { surveys.dispose(); survey.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
