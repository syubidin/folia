import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage();

  static const _key = 'folia_supabase_session';
  static const _storage = FlutterSecureStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return await _storage.containsKey(key: _key);
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: _key);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _key);
  }

  @override
  Future<void> persistSession(String session) async {
    await _storage.write(key: _key, value: session);
  }
}
