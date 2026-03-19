import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<Map<String, String>> readAll() => _storage.readAll();

  Future<void> deleteAll() => _storage.deleteAll();

  // Convenience methods for credential management
  Future<({String host, String projectId, String apiKey})?> readCredentials() async {
    final host = await read('host');
    final projectId = await read('projectId');
    final apiKey = await read('apiKey');
    if (host == null || projectId == null || apiKey == null) return null;
    return (host: host, projectId: projectId, apiKey: apiKey);
  }

  Future<void> saveCredentials({
    required String host,
    required String projectId,
    required String apiKey,
  }) async {
    await write('host', host);
    await write('projectId', projectId);
    await write('apiKey', apiKey);
  }

  Future<void> clearCredentials() async {
    await delete('host');
    await delete('projectId');
    await delete('apiKey');
  }
}
