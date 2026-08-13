import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de organizações.
class OrganizationApi {
  final ApiClient _client;

  OrganizationApi(this._client);

  Future<List<Organization>> list() =>
      _client.getList('/api/v1/organizations', Organization.fromJson);

  Future<Organization> getById(String id) =>
      _client.getOne('/api/v1/organizations/$id', Organization.fromJson);

  Future<Organization> create(Map<String, dynamic> body) async {
    // POST retorna {id, tradeName, message}: busca o registro completo depois.
    final id = await _client.post<String>(
      '/api/v1/organizations',
      body,
      (json) => json['id'] as String,
    );
    return getById(id);
  }

  Future<Organization> update(String id, Map<String, dynamic> body) =>
      _client.put('/api/v1/organizations/$id', body, Organization.fromJson);
}
