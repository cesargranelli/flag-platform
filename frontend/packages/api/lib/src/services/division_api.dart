import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de divisões.
class DivisionApi {
  final ApiClient _client;

  DivisionApi(this._client);

  /// Lista as divisões de um campeonato (endpoint público).
  Future<List<Division>> listByCompetition(String competitionId) =>
      _client.getList(
        '/api/v1/competitions/$competitionId/divisions',
        Division.fromJson,
      );

  /// Detalhe de uma divisão (endpoint público).
  Future<Division> getById(String id) =>
      _client.getOne('/api/v1/divisions/$id', Division.fromJson);

  Future<Division> create({
    required String competitionId,
    String? conferenceId,
    required String name,
  }) => _client.post('/api/v1/competitions/$competitionId/divisions', {
    'conferenceId': ?conferenceId,
    'name': name,
  }, Division.fromJson);

  Future<Division> update(
    String id, {
    required String competitionId,
    String? conferenceId,
    required String name,
  }) => _client.put('/api/v1/divisions/$id', {
    'competitionId': competitionId,
    'conferenceId': ?conferenceId,
    'name': name,
  }, Division.fromJson);

  /// Exclui uma divisão (a estrutura só é alterável em DRAFT).
  Future<void> delete(String id) => _client.delete('/api/v1/divisions/$id');
}
