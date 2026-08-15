import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gerencia a sessão do usuário autenticado (token JWT e roles).
///
/// Uso: [Public App] não precisa; [Referee App] e [Admin Web] usam após login.
class SessionManager {
  static const _tokenKey = 'auth_token';
  static const _rolesKey = 'auth_roles';
  static const _userNameKey = 'auth_user_name';
  static const _keepConnectedKey = 'auth_keep_connected';

  final FlutterSecureStorage _storage;

  SessionManager([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    required List<String> roles,
    String? userName,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _rolesKey, value: roles.join(','));
    if (userName != null) {
      await _storage.write(key: _userNameKey, value: userName);
    }
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: _rolesKey);
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',').where((r) => r.isNotEmpty).toList();
  }

  Future<String?> getUserName() => _storage.read(key: _userNameKey);

  Future<bool> isAuthenticated() async => (await getToken()) != null;

  Future<void> saveKeepConnected(bool value) =>
      _storage.write(key: _keepConnectedKey, value: value.toString());

  Future<bool> isKeepConnected() async =>
      (await _storage.read(key: _keepConnectedKey)) == 'true';

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _rolesKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _keepConnectedKey);
  }
}
