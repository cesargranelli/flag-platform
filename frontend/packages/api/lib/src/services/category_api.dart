import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de categorias.
class CategoryApi {
  final ApiClient _client;

  CategoryApi(this._client);

  /// Lista as categorias de um campeonato (endpoint público).
  Future<List<Category>> listByCompetition(String competitionId) =>
      _client.getList(
        '/api/v1/competitions/$competitionId/categories',
        Category.fromJson,
      );

  Future<Category> create({
    required String competitionId,
    required String name,
  }) =>
      _client.post(
        '/api/v1/categories',
        {'competitionId': competitionId, 'name': name},
        Category.fromJson,
      );

  Future<Category> update(
    String id, {
    required String competitionId,
    required String name,
  }) =>
      _client.put(
        '/api/v1/categories/$id',
        {'competitionId': competitionId, 'name': name},
        Category.fromJson,
      );

  Future<void> delete(String id) => _client.delete('/api/v1/categories/$id');
}
