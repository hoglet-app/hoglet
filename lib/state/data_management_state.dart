import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/event_definition.dart';
import '../services/posthog_client.dart';

class DataManagementState {
  final eventDefinitions = Signal<List<EventDefinition>>([]);
  final propertyDefinitions = Signal<List<Map<String, dynamic>>>([]);
  final isLoadingEvents = Signal(false);
  final isLoadingProperties = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchEventDefinitions(PosthogClient client, String host, String projectId, String apiKey, {String? search}) async {
    isLoadingEvents.value = true; error.value = null;
    try { eventDefinitions.value = await client.fetchEventDefinitions(host, projectId, apiKey, search: search); }
    catch (e) { error.value = e; }
    finally { isLoadingEvents.value = false; }
  }

  Future<void> fetchPropertyDefinitions(PosthogClient client, String host, String projectId, String apiKey, {String type = 'event'}) async {
    isLoadingProperties.value = true; error.value = null;
    try { propertyDefinitions.value = await client.fetchPropertyDefinitions(host, projectId, apiKey, type: type); }
    catch (e) { error.value = e; }
    finally { isLoadingProperties.value = false; }
  }

  void dispose() { eventDefinitions.dispose(); propertyDefinitions.dispose(); isLoadingEvents.dispose(); isLoadingProperties.dispose(); error.dispose(); }
}
