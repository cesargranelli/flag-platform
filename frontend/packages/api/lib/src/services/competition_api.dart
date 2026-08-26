import 'package:flag_domain/flag_domain.dart';

import '../api_client.dart';

/// Serviço REST de campeonatos.
class CompetitionApi {
  final ApiClient _client;

  CompetitionApi(this._client);

  /// Lista todos os campeonatos (endpoint público, ordenado por nome).
  /// ADMIN pode passar includeDisabled para receber também os desativados.
  Future<List<Competition>> listAll({bool includeDisabled = false}) =>
      _client.getList(
        '/api/v1/competitions?includeDisabled=$includeDisabled',
        Competition.fromJson,
      );

  Future<List<Competition>> listByOrganization(String organizationId) =>
      _client.getList(
        '/api/v1/organizations/$organizationId/competitions',
        Competition.fromJson,
      );

  Future<Competition> getById(String id) =>
      _client.getOne('/api/v1/competitions/$id', Competition.fromJson);

  /// Exclusão lógica: marca o campeonato como desativado (DISABLED).
  Future<void> deactivate(String id) =>
      _client.delete('/api/v1/competitions/$id');

  /// Reativa o campeonato (exclusivo ADMIN), voltando para DRAFT.
  Future<void> reactivate(String id) =>
      _client.post('/api/v1/competitions/$id/reactivate', <String, dynamic>{},
          (json) => json);

  Future<Competition> create({
    required String organizationId,
    required String name,
    String? description,
    String? startDate,
    String? endDate,
    CompetitionStatus? status,
    Modality? modality,
    String? gender,
    String? ageGroup,
    GroupingType? groupingType,
  }) => _client.post(
    '/api/v1/competitions',
    _body(
      organizationId: organizationId,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      status: status,
      modality: modality,
      gender: gender,
      ageGroup: ageGroup,
      groupingType: groupingType,
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
    Modality? modality,
    String? gender,
    String? ageGroup,
    GroupingType? groupingType,
  }) => _client.put(
    '/api/v1/competitions/$id',
    _body(
      organizationId: organizationId,
      name: name,
      description: description,
      startDate: startDate,
      endDate: endDate,
      status: status,
      modality: modality,
      gender: gender,
      ageGroup: ageGroup,
      groupingType: groupingType,
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
    Modality? modality,
    String? gender,
    String? ageGroup,
    GroupingType? groupingType,
  }) => {
    'organizationId': organizationId,
    'name': name,
    if (description != null && description.isNotEmpty)
      'description': description,
    'startDate': ?startDate,
    'endDate': ?endDate,
    'status': ?(status?.toJson()),
    'modality': ?(modality?.toJson()),
    'gender': ?gender,
    'ageGroup': ?ageGroup,
    'groupingType': ?(groupingType?.toJson()),
  };
}
