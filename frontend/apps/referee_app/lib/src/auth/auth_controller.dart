import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/foundation.dart';

/// Estado de autenticação do Referee App.
class AuthState {
  /// `true` enquanto a sessão persistida está sendo restaurada no boot
  /// (issue #425#27) — evita o flash de login para usuários com token.
  final bool restoring;
  final bool authenticated;
  final User? user;

  const AuthState({
    this.restoring = false,
    this.authenticated = false,
    this.user,
  });
}

/// Controla a sessão da mesa: login, restauração e logout.
class AuthController extends ChangeNotifier {
  final SessionManager _session;
  final AuthApi _api;

  AuthState _state = const AuthState(restoring: true);

  AuthState get state => _state;

  AuthController({required SessionManager session, required AuthApi api})
      : _session = session,
        _api = api;

  Future<void> restore() async {
    try {
      final token = await _session.getToken();
      if (token == null) {
        _set(const AuthState());
        return;
      }
      final user = await _api.me();
      _set(AuthState(authenticated: true, user: user));
    } catch (_) {
      try {
        await _session.clear();
      } catch (_) {
        // Ignora falha de limpeza do storage.
      }
      _set(const AuthState());
    }
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _api.login(email: email, password: password);
    await _session.saveSession(
      token: response.token,
      roles: [response.user.role.toJson()],
      userName: response.user.name,
    );
    _set(AuthState(authenticated: true, user: response.user));
  }

  Future<void> logout() async {
    try {
      await _session.clear();
    } catch (_) {
      // Ignora falha de limpeza do storage.
    }
    _set(const AuthState());
  }

  void _set(AuthState next) {
    _state = next;
    notifyListeners();
  }
}