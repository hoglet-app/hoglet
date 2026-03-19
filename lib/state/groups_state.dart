import 'package:flutter_solidart/flutter_solidart.dart';
import '../models/group.dart';
import '../services/posthog_client.dart';

class GroupsState {
  final groupTypes = Signal<List<GroupType>>([]);
  final groups = Signal<List<Group>>([]);
  final selectedTypeIndex = Signal<int>(0);
  final isLoading = Signal(false);
  final isLoadingTypes = Signal(false);
  final error = Signal<Object?>(null);

  Future<void> fetchGroupTypes(PosthogClient client, String host, String projectId, String apiKey) async {
    isLoadingTypes.value = true; error.value = null;
    try { groupTypes.value = await client.fetchGroupTypes(host, projectId, apiKey); }
    catch (e) { error.value = e; }
    finally { isLoadingTypes.value = false; }
  }

  Future<void> fetchGroups(PosthogClient client, String host, String projectId, String apiKey, {String? search}) async {
    isLoading.value = true; error.value = null;
    try { groups.value = await client.fetchGroups(host, projectId, apiKey, groupTypeIndex: selectedTypeIndex.value, search: search); }
    catch (e) { error.value = e; }
    finally { isLoading.value = false; }
  }

  void selectType(int index) { selectedTypeIndex.value = index; }

  void dispose() { groupTypes.dispose(); groups.dispose(); selectedTypeIndex.dispose(); isLoading.dispose(); isLoadingTypes.dispose(); error.dispose(); }
}
