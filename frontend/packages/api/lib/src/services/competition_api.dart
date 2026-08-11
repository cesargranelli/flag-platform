import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de campeonatos.
class CompetitionApi {
  final ApiClient _client;

  CompetitionApi(this._client);

  Future<List<Competition>> listByOrganization(int organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/competitions',
        Competition.fromJson,
      );

  Future<Competition> getById(int id) =>
      _client.getOne('/api/v1/competitions/$id', Competition.fromJson);

  Future<Competition> create({
    required String name,
    required int organizationId,
    required CompetitionStatus status,
  }) =>
      _client.post(
        '/api/v1/competitions',
        {
          'name': name,
          'organizationId': organizationId,
          'status': status.toJson(),
        },
        Competition.fromJson,
      );
}
