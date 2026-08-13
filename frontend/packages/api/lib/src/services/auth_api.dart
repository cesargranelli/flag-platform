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
}
