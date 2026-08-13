import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de rodadas.
class RoundApi {
  final ApiClient _client;

  RoundApi(this._client);

  Future<List<Round>> listByCategory(String categoryId) => _client.getList(
        '/api/v1/categories/$categoryId/rounds',
        Round.fromJson,
      );

  Future<Round> create({
    required String categoryId,
    required int number,
    required String name,
    required RoundType type,
  }) =>
      _client.post(
        '/api/v1/rounds',
        {
          'categoryId': categoryId,
          'number': number,
          'name': name,
          'type': type.toJson(),
        },
        Round.fromJson,
      );

  Future<Round> update(
    String id, {
    required String categoryId,
    required int number,
    required String name,
    required RoundType type,
  }) =>
      _client.put(
        '/api/v1/rounds/$id',
        {
          'categoryId': categoryId,
          'number': number,
          'name': name,
          'type': type.toJson(),
        },
        Round.fromJson,
      );
}
