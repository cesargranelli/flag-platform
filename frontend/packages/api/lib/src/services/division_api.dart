import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de divisões.
class DivisionApi {
  final ApiClient _client;

  DivisionApi(this._client);

  /// Lista as divisões de uma categoria (endpoint público).
  Future<List<Division>> listByCategory(String categoryId) =>
      _client.getList(
        '/api/v1/categories/$categoryId/divisions',
        Division.fromJson,
      );

  /// Detalhe de uma divisão (endpoint público).
  Future<Division> getById(String id) =>
      _client.getOne('/api/v1/divisions/$id', Division.fromJson);

  Future<Division> create({
    required String categoryId,
    String? conferenceId,
    required String name,
  }) =>
      _client.post(
        '/api/v1/categories/$categoryId/divisions',
        {
          'conferenceId': conferenceId,
          'name': name,
        },
        Division.fromJson,
      );

  Future<Division> update(
    String id, {
    String? conferenceId,
    required String name,
  }) =>
      _client.put(
        '/api/v1/divisions/$id',
        {
          'conferenceId': conferenceId,
          'name': name,
        },
        Division.fromJson,
      );
}