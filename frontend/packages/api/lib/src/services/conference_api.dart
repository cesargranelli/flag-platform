import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de conferências.
class ConferenceApi {
  final ApiClient _client;

  ConferenceApi(this._client);

  /// Lista as conferências de uma categoria (endpoint público).
  Future<List<Conference>> listByCategory(String categoryId) =>
      _client.getList(
        '/api/v1/categories/$categoryId/conferences',
        Conference.fromJson,
      );

  /// Detalhe de uma conferência (endpoint público).
  Future<Conference> getById(String id) =>
      _client.getOne('/api/v1/conferences/$id', Conference.fromJson);

  Future<Conference> create({
    required String categoryId,
    required String name,
  }) =>
      _client.post(
        '/api/v1/categories/$categoryId/conferences',
        {
          'name': name,
        },
        Conference.fromJson,
      );

  Future<Conference> update(
    String id, {
    required String name,
  }) =>
      _client.put(
        '/api/v1/conferences/$id',
        {
          'name': name,
        },
        Conference.fromJson,
      );
}