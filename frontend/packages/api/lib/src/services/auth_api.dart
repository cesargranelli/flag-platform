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
}
