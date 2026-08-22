import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de times.
class TeamApi {
  final ApiClient _client;

  TeamApi(this._client);

  /// Lista os times de um campeonato (endpoint público).
  Future<List<Team>> listByCompetition(String competitionId) => _client.getList(
    '/api/v1/competitions/$competitionId/teams',
    Team.fromJson,
  );

  Future<Team> getById(String id) =>
      _client.getOne('/api/v1/teams/$id', Team.fromJson);

  /// Cria um time.
  ///
  /// O backend espera `POST /api/v1/teams` com corpo completo
  /// (`organizationId` e `competitionId` obrigatórios).
  Future<Team> create({
    required String organizationId,
    required String competitionId,
    String? divisionId,
    required String name,
    String? shortName,
    String? document,
    DocumentType? documentType,
    String? logoUrl,
  }) => _client.post('/api/v1/teams', {
    'organizationId': organizationId,
    'competitionId': competitionId,
    'divisionId': ?divisionId,
    'name': name,
    'shortName': ?shortName,
    'document': ?document,
    'documentType': documentType?.toJson(),
    'logoUrl': ?logoUrl,
  }, Team.fromJson);

  /// Atualiza um time enviando o MESMO corpo completo da criação
  /// (o backend exige `organizationId` com `@NotNull`).
  Future<Team> update(
    String id, {
    required String organizationId,
    required String competitionId,
    String? divisionId,
    required String name,
    String? shortName,
    String? document,
    DocumentType? documentType,
    String? logoUrl,
  }) => _client.put('/api/v1/teams/$id', {
    'organizationId': organizationId,
    'competitionId': competitionId,
    'divisionId': ?divisionId,
    'name': name,
    'shortName': ?shortName,
    'document': ?document,
    'documentType': documentType?.toJson(),
    'logoUrl': ?logoUrl,
  }, Team.fromJson);
}
