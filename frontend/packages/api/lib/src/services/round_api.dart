import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de rodadas.
class RoundApi {
  final ApiClient _client;

  RoundApi(this._client);

  /// Lista as rodadas de um campeonato (endpoint público).
  Future<List<Round>> listByCompetition(String competitionId) => _client
      .getList('/api/v1/competitions/$competitionId/rounds', Round.fromJson);

  /// Detalhe de uma rodada (endpoint público).
  Future<Round> getById(String id) =>
      _client.getOne('/api/v1/rounds/$id', Round.fromJson);

  Future<Round> create({
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  }) => _client.post('/api/v1/competitions/$competitionId/rounds', {
    'number': number,
    'name': name,
    'type': type.toJson(),
  }, Round.fromJson);

  Future<Round> update(
    String id, {
    required String competitionId,
    required int number,
    required String name,
    required RoundType type,
  }) => _client.put('/api/v1/rounds/$id', {
    'competitionId': competitionId,
    'number': number,
    'name': name,
    'type': type.toJson(),
  }, Round.fromJson);
}
