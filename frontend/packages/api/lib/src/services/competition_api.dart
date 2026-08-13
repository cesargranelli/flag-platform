import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de campeonatos.
class CompetitionApi {
  final ApiClient _client;

  CompetitionApi(this._client);

  /// Lista todos os campeonatos (endpoint público, ordenado por nome).
  Future<List<Competition>> listAll() =>
      _client.getList('/api/v1/competitions', Competition.fromJson);

  Future<List<Competition>> listByOrganization(String organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/competitions',
        Competition.fromJson,
      );

  Future<Competition> getById(String id) =>
      _client.getOne('/api/v1/competitions/$id', Competition.fromJson);

  Future<Competition> create({
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
  }) =>
      _client.post(
        '/api/v1/competitions',
        _body(
          organizationId: organizationId,
          name: name,
          description: description,
          startDate: startDate,
          endDate: endDate,
          status: status,
        ),
        Competition.fromJson,
      );

  Future<Competition> update(
    String id, {
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
  }) =>
      _client.put(
        '/api/v1/competitions/$id',
        _body(
          organizationId: organizationId,
          name: name,
          description: description,
          startDate: startDate,
          endDate: endDate,
          status: status,
        ),
        Competition.fromJson,
      );

  Map<String, dynamic> _body({
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
  }) =>
      {
        'organizationId': organizationId,
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (status != null) 'status': status.toJson(),
      };
}
