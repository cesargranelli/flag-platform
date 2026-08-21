import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de times.
class TeamApi {
  final ApiClient _client;

  TeamApi(this._client);

  Future<List<Team>> listByCompetition(String competitionId) => _client.getList(
        '/api/v1/competitions/$competitionId/teams',
        Team.fromJson,
      );

  Future<Team> getById(String id) =>
      _client.getOne('/api/v1/teams/$id', Team.fromJson);

  Future<Team> create({
    required String organizationId,
    String? competitionId,
    required String name,
    String? shortName,
    String? document,
    DocumentType? documentType,
    String? logoUrl,
  }) =>
      _client.post(
        '/api/v1/teams',
        {
          'organizationId': organizationId,
          'competitionId': competitionId,
          'name': name,
          'shortName': ?shortName,
          'document': ?document,
          'documentType': documentType?.toJson(),
          'logoUrl': ?logoUrl,
        },
        Team.fromJson,
      );

  Future<Team> update(
    String id, {
    required String organizationId,
    String? competitionId,
    required String name,
    String? shortName,
    String? document,
    DocumentType? documentType,
    String? logoUrl,
  }) =>
      _client.put(
        '/api/v1/teams/$id',
        {
          'organizationId': organizationId,
          'competitionId': ?competitionId,
          'name': name,
          'shortName': ?shortName,
          'document': ?document,
          'documentType': documentType?.toJson(),
          'logoUrl': ?logoUrl,
        },
        Team.fromJson,
      );
}

