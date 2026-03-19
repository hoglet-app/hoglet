import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/product_tour.dart';
import '../services/posthog_client.dart';

class ProductToursState {
  final tours = Signal<List<ProductTour>>([]);
  final tour = Signal<ProductTour?>(null);
  final isLoading = Signal(false);
  final isLoadingDetail = Signal(false);
  final error = Signal<Object?>(null);
  final detailError = Signal<Object?>(null);

  Future<void> fetchTours(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoading.value = true; error.value = null;
    try { tours.value = await client.fetchProductTours(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  Future<void> fetchTour(PosthogClient client, String host, String projectId, String apiKey, String id) async {
    isLoadingDetail.value = true; detailError.value = null;
    try { tour.value = await client.fetchProductTour(host, projectId, apiKey, id); }
    catch (e) { detailError.value = e; }
    finally { isLoadingDetail.value = false; }
  }

  void dispose() { tours.dispose(); tour.dispose(); isLoading.dispose(); isLoadingDetail.dispose(); error.dispose(); detailError.dispose(); }
}
