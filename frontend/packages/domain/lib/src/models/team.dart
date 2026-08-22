import '../enums/document_type.dart';

/// Time de uma competição.
///
/// Shape de `/api/v1/teams` e de
/// `/api/v1/competitions/{competitionId}/teams`.
class Team {
  final String id;

  /// Organização (clube) inscrita — obrigatória no backend ao criar/atualizar.
  final String? organizationId;
  final String competitionId;
  final String? divisionId;
  final String name;
  final String? shortName;
  final String? sportName;
  final int? athleteCount;
  final String? document;
  final DocumentType? documentType;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    this.organizationId,
    required this.competitionId,
    this.divisionId,
    required this.name,
    this.shortName,
    this.sportName,
    this.athleteCount,
    this.document,
    this.documentType,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    organizationId: json['organizationId'] as String?,
    competitionId: json['competitionId'] as String,
    divisionId: json['divisionId'] as String?,
    name: json['name'] as String,
    shortName: json['shortName'] as String?,
    sportName: json['sportName'] as String?,
    athleteCount: json['athleteCount'] as int?,
    document: json['document'] as String?,
    documentType: json['documentType'] is String
        ? DocumentType.fromJson(json['documentType'] as String)
        : null,
    logoUrl: json['logoUrl'] as String?,
    createdAt: json['createdAt'] is String
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] is String
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/teams`).
  ///
  /// `organizationId` e `competitionId` são obrigatórios no backend
  /// (`@NotNull`); os demais são opcionais.
  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'competitionId': competitionId,
    if (divisionId != null) 'divisionId': divisionId,
    'name': name,
    if (shortName != null) 'shortName': shortName,
    if (sportName != null) 'sportName': sportName,
    if (athleteCount != null) 'athleteCount': athleteCount,
    if (document != null) 'document': document,
    if (documentType != null) 'documentType': documentType!.toJson(),
    if (logoUrl != null) 'logoUrl': logoUrl,
  };
}
