import '../enums/document_type.dart';

/// Time de uma competição.
///
/// Shape de `/api/v1/competitions/{competitionId}/teams`.
class Team {
  final String id;
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
  Map<String, dynamic> toJson() => {
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
}
