// lib/services/session_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'username';

  static Future<void> saveSession(String token, {String? username}) async {
    await _storage.write(key: _tokenKey, value: token);
    if (username != null) {
      await _storage.write(key: _usernameKey, value: username);
    }
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
