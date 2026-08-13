import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de times.
class TeamApi {
  final ApiClient _client;

  TeamApi(this._client);

  Future<List<Team>> listByCategory(String categoryId) => _client.getList(
        '/api/v1/categories/$categoryId/teams',
        Team.fromJson,
      );

  Future<Team> getById(String id) =>
      _client.getOne('/api/v1/teams/$id', Team.fromJson);

  Future<Team> create({
    required String categoryId,
    required String name,
    String? shortName,
    String? logoUrl,
  }) =>
      _client.post(
        '/api/v1/teams',
        {
          'categoryId': categoryId,
          'name': name,
          'shortName': ?shortName,
          'logoUrl': ?logoUrl,
        },
        Team.fromJson,
      );

  Future<Team> update(
    String id, {
    required String categoryId,
    required String name,
    String? shortName,
    String? logoUrl,
  }) =>
      _client.put(
        '/api/v1/teams/$id',
        {
          'categoryId': categoryId,
          'name': name,
          'shortName': ?shortName,
          'logoUrl': ?logoUrl,
        },
        Team.fromJson,
      );
}

