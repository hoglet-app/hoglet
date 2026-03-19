import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/feature_flag.dart';
import '../services/posthog_client.dart';

class FlagsState {
  FlagsState({required this.client});

  final PosthogClient client;

  final flags = Signal<List<FeatureFlag>>([]);
  final isLoading = Signal(false);
  final error = Signal<Object?>(null);

  final selectedFlag = Signal<FeatureFlag?>(null);
  final isLoadingDetail = Signal(false);
  final detailError = Signal<Object?>(null);

  Future<void> fetchFlags({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await client.fetchFeatureFlags(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
      );
      flags.value = result;
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFlag({
    required String host,
    required String projectId,
    required String apiKey,
    required int flagId,
  }) async {
    isLoadingDetail.value = true;
    detailError.value = null;
    try {
      final result = await client.fetchFeatureFlag(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        flagId: flagId,
      );
      selectedFlag.value = result;
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> toggleFlag({
    required String host,
    required String projectId,
    required String apiKey,
    required int flagId,
    required bool active,
  }) async {
    try {
      final updated = await client.toggleFeatureFlag(
        host: host,
        projectId: projectId,
        apiKey: apiKey,
        flagId: flagId,
        active: active,
      );
      // Update flag in the list
      flags.value = flags.value
          .map((f) => f.id == flagId ? updated : f)
          .toList();
      // Update selectedFlag if it matches
      if (selectedFlag.value?.id == flagId) {
        selectedFlag.value = updated;
      }
    } catch (e) {
      error.value = e;
    }
  }

  void dispose() {
    flags.dispose();
    isLoading.dispose();
    error.dispose();
    selectedFlag.dispose();
    isLoadingDetail.dispose();
    detailError.dispose();
  }
}
