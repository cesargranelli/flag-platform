import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/foundation.dart';

/// Estado de autenticação do Admin Web.
class AuthState {
  final bool authenticated;
  final User? user;

  const AuthState({this.authenticated = false, this.user});
}

/// Controla a sessão do organizador: login, restauração e logout.
///
/// Persiste o token via [SessionManager] e notifica a árvore (e o GoRouter,
/// via [ChangeNotifier]) quando o estado muda.
class AuthController extends ChangeNotifier {
  final SessionManager _session;
  final AuthApi _api;

  AuthState _state = const AuthState();

  AuthState get state => _state;

  AuthController({required SessionManager session, required AuthApi api})
      : _session = session,
        _api = api;

  /// Restaura a sessão ao iniciar: se existir token, valida via `/auth/me`.
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

  /// Autentica com e-mail/senha e persiste o token JWT.
  Future<void> login({
    required String email,
    required String password,
    bool keepConnected = false,
  }) async {
    final response = await _api.login(email: email, password: password);
    await _session.saveSession(
      token: response.token,
      roles: [response.user.role],
      userName: response.user.name,
    );
    await _session.saveKeepConnected(keepConnected);
    _set(AuthState(authenticated: true, user: response.user));
  }

  /// Encerra a sessão, removendo o token persistido.
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
