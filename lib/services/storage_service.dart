import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const keyHost = 'posthog_host';
  static const keyHostMode = 'posthog_host_mode';
  static const keyCustomHost = 'posthog_custom_host';
  static const keyProjectId = 'posthog_project_id';
  static const keyApiKey = 'posthog_personal_api_key';
  static const keyVisibleColumns = 'hoglet_visible_columns';

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearAll() async {
    await _storage.delete(key: keyHost);
    await _storage.delete(key: keyHostMode);
    await _storage.delete(key: keyCustomHost);
    await _storage.delete(key: keyProjectId);
    await _storage.delete(key: keyApiKey);
    await _storage.delete(key: keyVisibleColumns);
  }
}
