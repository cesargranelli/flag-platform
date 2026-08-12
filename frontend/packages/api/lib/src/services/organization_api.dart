import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de organizações.
class OrganizationApi {
  final ApiClient _client;

  OrganizationApi(this._client);

  Future<List<Organization>> list() =>
      _client.getList('/api/v1/organizations', Organization.fromJson);

  Future<Organization> getById(int id) =>
      _client.getOne('/api/v1/organizations/$id', Organization.fromJson);

  Future<Organization> create({
    required String name,
    required String slug,
  }) =>
      _client.post(
        '/api/v1/organizations',
        {'name': name, 'slug': slug},
        Organization.fromJson,
      );

  Future<Organization> update(
    int id, {
    required String name,
    required String slug,
  }) =>
      _client.put(
        '/api/v1/organizations/$id',
        {'name': name, 'slug': slug},
        Organization.fromJson,
      );
}
