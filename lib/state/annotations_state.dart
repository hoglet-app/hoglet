import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/annotation.dart';
import '../services/posthog_client.dart';

class AnnotationsState {
  final annotations = Signal<List<Annotation>>([]);
  final annotation = Signal<Annotation?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchAnnotations(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { annotations.value = await client.fetchAnnotations(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchAnnotation(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { annotation.value = await client.fetchAnnotation(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  Future<Annotation> createAnnotation(
    PosthogClient client, String host, String projectId, String apiKey, {
    required String content,
    required String dateMarker,
    String scope = 'project',
    int? dashboardItem,
    int? dashboardId,
  }) async {
    final created = await client.createAnnotation(
      host, projectId, apiKey,
      content: content,
      dateMarker: dateMarker,
      scope: scope,
      dashboardItem: dashboardItem,
      dashboardId: dashboardId,
    );
    annotations.value = [created, ...annotations.value];
    return created;
  }

  Future<void> updateAnnotation(
    PosthogClient client, String host, String projectId, String apiKey, int id, {
    String? content,
    String? dateMarker,
    String? scope,
  }) async {
    final updated = await client.updateAnnotation(host, projectId, apiKey, id, content: content, dateMarker: dateMarker, scope: scope);
    annotation.value = updated;
    final current = List<Annotation>.from(annotations.value);
    final idx = current.indexWhere((a) => a.id == id);
    if (idx != -1) { current[idx] = updated; annotations.value = current; }
  }

  Future<void> deleteAnnotation(PosthogClient client, String host, String projectId, String apiKey, int id) async {
    await client.deleteAnnotation(host, projectId, apiKey, id);
    annotations.value = annotations.value.where((a) => a.id != id).toList();
    if (annotation.value?.id == id) annotation.value = null;
  }

  void dispose() { annotations.dispose(); annotation.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
