import '../enums/competition_status.dart';
import '../enums/grouping_type.dart';
import '../enums/modality.dart';

/// Campeonato do Flag Platform.
///
/// Aceita os dois shapes retornados pela API:
/// - resumo (`GET /api/v1/competitions`): id, name, organizationName, status;
/// - completo (`GET /api/v1/competitions/{id}`): id, organizationId, name,
///   description, startDate, endDate, status, createdBy, createdAt, updatedAt.
class Competition {
  /// Identificador UUID do campeonato.
  final String id;

  final String name;

  final CompetitionStatus status;

  final String? organizationId;

  /// Presente no shape de resumo (`GET /api/v1/competitions`).
  final String? organizationName;

  final String? description;

  final DateTime? startDate;

  final DateTime? endDate;

  /// Atributos da competição (adicionados na V24).
  final Modality? modality;

  final String? gender;

  final String? ageGroup;

  /// Rótulo do agrupamento da estrutura — Divisões | Grupos (#308).
  /// Nulo em registros legados (tratado como Divisões).
  final GroupingType? groupingType;

  /// UUID do usuário criador do campeonato (base da regra de edição
  /// restrita ao criador ou ADMIN). Nulo em registros legados.
  final String? createdBy;

  const Competition({
    required this.id,
    required this.name,
    required this.status,
    this.organizationId,
    this.organizationName,
    this.description,
    this.startDate,
    this.endDate,
    this.modality,
    this.gender,
    this.ageGroup,
    this.groupingType,
    this.createdBy,
  });

  factory Competition.fromJson(Map<String, dynamic> json) => Competition(
        id: json['id'] as String,
        name: json['name'] as String,
        status: CompetitionStatus.fromJson(json['status'] as String),
        organizationId: json['organizationId'] as String?,
        organizationName: json['organizationName'] as String?,
        description: json['description'] as String?,
        startDate: _tryParseDate(json['startDate']),
        endDate: _tryParseDate(json['endDate']),
        modality: json['modality'] == null
            ? null
            : Modality.fromJson(json['modality'] as String),
        gender: json['gender'] as String?,
        ageGroup: json['ageGroup'] as String?,
        groupingType: GroupingType.tryFromJson(
            json['groupingType'] as String?),
        createdBy: json['createdBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.toJson(),
        if (organizationId != null) 'organizationId': organizationId,
        if (organizationName != null) 'organizationName': organizationName,
        if (description != null) 'description': description,
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        if (modality != null) 'modality': modality!.toJson(),
        if (gender != null) 'gender': gender,
        if (ageGroup != null) 'ageGroup': ageGroup,
        if (groupingType != null) 'groupingType': groupingType!.toJson(),
        if (createdBy != null) 'createdBy': createdBy,
      };
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
