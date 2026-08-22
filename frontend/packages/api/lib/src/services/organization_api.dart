import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de organizações.
class OrganizationApi {
  final ApiClient _client;

  OrganizationApi(this._client);

  Future<List<Organization>> list({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/organizations?includeDisabled=$includeDisabled',
        Organization.fromJson,
      );

  Future<Organization> getById(String id) =>
      _client.getOne('/api/v1/organizations/$id', Organization.fromJson);

  /// Exclusão lógica: marca a organização como desativada (INACTIVE).
  Future<void> deactivate(String id) =>
      _client.delete('/api/v1/organizations/$id');

  /// Reativa a organização (exclusivo ADMIN).
  Future<void> reactivate(String id) =>
      _client.post('/api/v1/organizations/$id/reactivate', <String, dynamic>{},
          (json) => json);

  Future<Organization> create(Map<String, dynamic> body) async {
    // POST retorna {id, tradeName, message}: busca o registro completo depois.
    final id = await _client.post<String>(
      '/api/v1/organizations',
      body,
      (json) => json['id'] as String,
    );
    return getById(id);
  }
}
