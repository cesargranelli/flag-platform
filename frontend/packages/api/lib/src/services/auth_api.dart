import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de autenticação e usuário atual.
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) =>
      _client.post(
        '/api/v1/auth/login',
        {'email': email, 'password': password},
        LoginResponse.fromJson,
      );

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _client.post(
        '/api/v1/auth/register',
        {'name': name, 'email': email, 'password': password},
        User.fromJson,
      );

  Future<User> me() =>
      _client.getOne('/api/v1/auth/me', User.fromJson);

  Future<List<User>> listUsers() =>
      _client.getList('/api/v1/auth/users', User.fromJson);

  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) =>
      _client.post(
        '/api/v1/auth/users',
        {'name': name, 'email': email, 'password': password, 'role': role},
        User.fromJson,
      );

  Future<List<User>> listPendingUsers() =>
      _client.getList('/api/v1/auth/users/pending', User.fromJson);

  Future<User> approveUser(String id) => _client.post(
        '/api/v1/auth/users/$id/approve',
        {},
        User.fromJson,
      );

  Future<User> rejectUser(String id) => _client.post(
        '/api/v1/auth/users/$id/reject',
        {},
        User.fromJson,
      );

  Future<String> forgotPassword(String email) async {
    final result = await _client.post<String>(
      '/api/v1/auth/forgot-password',
      {'email': email},
      (json) => json['resetToken'] as String? ?? '',
    );
    return result;
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _client.post(
        '/api/v1/auth/reset-password',
        {'token': token, 'newPassword': newPassword},
        (json) => json,
      );
}
