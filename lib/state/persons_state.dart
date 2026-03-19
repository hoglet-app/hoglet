import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/person.dart';
import '../services/posthog_client.dart';

class PersonsState {
  final persons = Signal<List<Person>>([]);
  final person = Signal<Person?>(null);
  final isLoading = Signal(false);
  final isLoadingMore = Signal(false);
  final isLoadingDetail = Signal(false);
  final hasMore = Signal(true);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  static const _pageSize = 100;
  int _offset = 0;
  String? _lastSearch;

  Future<void> fetchPersons(PosthogClient client, String host, String projectId, String apiKey, {String? search}) async {
    isLoading.value = true;
    error.value = null;
    _offset = 0;
    _lastSearch = search;
    hasMore.value = true;
    try {
      final result = await client.fetchPersons(host, projectId, apiKey, search: search, limit: _pageSize, offset: 0);
      persons.value = result.persons;
      hasMore.value = result.hasNext;
      _offset = result.persons.length;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore(PosthogClient client, String host, String projectId, String apiKey) async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final result = await client.fetchPersons(host, projectId, apiKey, search: _lastSearch, limit: _pageSize, offset: _offset);
      persons.value = [...persons.value, ...result.persons];
      hasMore.value = result.hasNext;
      _offset += result.persons.length;
    } catch (_) {
      // Non-critical
    } finally {
      isLoadingMore.value = false;
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
    isLoadingMore.dispose();
    isLoadingDetail.dispose();
    hasMore.dispose();
    error.dispose();
    detailError.dispose();
  }
}
