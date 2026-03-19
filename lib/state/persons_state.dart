import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/person.dart';
import '../services/posthog_client.dart';

class PersonsState {
  final persons = Signal<List<Person>>([]);
  final person = Signal<Person?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchPersons(PosthogClient client, String host, String projectId, String apiKey, {String? search}) async {
    isLoading.value = true;
    error.value = null;
    try {
      persons.value = await client.fetchPersons(host, projectId, apiKey, search: search);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPerson(PosthogClient client, String host, String projectId, String apiKey, int personId) async {
    isLoadingDetail.value = true;
    detailError.value = null;
    try {
      person.value = await client.fetchPerson(host, projectId, apiKey, personId);
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  void dispose() {
    persons.dispose();
    person.dispose();
    isLoading.dispose();
    isLoadingDetail.dispose();
    error.dispose();
    detailError.dispose();
  }
}
