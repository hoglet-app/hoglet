import 'package:flutter_solidart/flutter_solidart.dart';

import '../models/feature_flag.dart';
import '../services/posthog_client.dart';

class FlagsState {
  final flags = Signal<List<FeatureFlag>>([]);
  final flag = Signal<FeatureFlag?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchFlags(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
  ) async {
    isLoading.value = true;
    error.value = null;
    try {
      flags.value = await client.fetchFeatureFlags(host, projectId, apiKey);
    } catch (e) {
      error.value = e;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFlag(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
    int flagId,
  ) async {
    isLoadingDetail.value = true;
    detailError.value = null;
    try {
      flag.value = await client.fetchFeatureFlag(host, projectId, apiKey, flagId);
    } catch (e) {
      detailError.value = e;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> toggleFlag(
    PosthogClient client,
    String host,
    String projectId,
    String apiKey,
    int flagId,
    bool active,
  ) async {
    try {
      final updated = await client.toggleFeatureFlag(
        host, projectId, apiKey, flagId, active,
      );

      // Update in list
      final currentFlags = List<FeatureFlag>.from(flags.value);
      final index = currentFlags.indexWhere((f) => f.id == flagId);
      if (index != -1) {
        currentFlags[index] = updated;
        flags.value = currentFlags;
      }

      // Update detail if viewing this flag
      if (flag.value?.id == flagId) {
        flag.value = updated;
      }
    } catch (e) {
      error.value = e;
      rethrow;
    }
  }

  void dispose() {
    flags.dispose();
    flag.dispose();
    isLoading.dispose();
    isLoadingDetail.dispose();
    error.dispose();
    detailError.dispose();
  }
}
