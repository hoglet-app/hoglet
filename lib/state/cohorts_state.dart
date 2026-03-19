import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/cohort.dart';
import '../models/person.dart';
import '../services/posthog_client.dart';

class CohortsState {
  final cohorts = Signal<List<Cohort>>([]);
  final cohort = Signal<Cohort?>(null);
  final cohortPersons = Signal<List<Person>>([]);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchCohorts(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true;
    error.value = null;
    try {
      cohorts.value = await client.fetchCohorts(host, projectId, apiKey);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCohort(PosthogClient client, String host, String projectId, String apiKey, int cohortId) async {
    isLoadingDetail.value = true;
    detailError.value = null;
    try {
      cohort.value = await client.fetchCohort(host, projectId, apiKey, cohortId);
      cohortPersons.value = await client.fetchCohortPersons(host, projectId, apiKey, cohortId);
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void dispose() {
    cohorts.dispose();
    cohort.dispose();
    cohortPersons.dispose();
    isLoading.dispose();
    isLoadingDetail.dispose();
    error.dispose();
    detailError.dispose();
  }
}
