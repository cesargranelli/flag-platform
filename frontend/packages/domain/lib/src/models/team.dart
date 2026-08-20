import '../enums/document_type.dart';

/// Time de uma categoria.
///
/// Shape de `/api/v1/teams`.
class Team {
  final String id;
  final String categoryId;
  final String? divisionId;
  final String name;
  final String? shortName;
  final String? document;
  final DocumentType? documentType;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    required this.categoryId,
    this.divisionId,
    required this.name,
    this.shortName,
    this.document,
    this.documentType,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        divisionId: json['divisionId'] as String?,
        name: json['name'] as String,
        shortName: json['shortName'] as String?,
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
        'categoryId': categoryId,
        if (divisionId != null) 'divisionId': divisionId,
        'name': name,
        if (shortName != null) 'shortName': shortName,
        if (document != null) 'document': document,
        if (documentType != null) 'documentType': documentType!.toJson(),
        if (logoUrl != null) 'logoUrl': logoUrl,
      };
}
