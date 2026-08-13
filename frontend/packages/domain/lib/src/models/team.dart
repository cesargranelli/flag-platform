/// Time de uma categoria.
///
/// Shape de `/api/v1/teams`.
class Team {
  final String id;
  final String categoryId;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    required this.categoryId,
    required this.name,
    this.shortName,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        shortName: json['shortName'] as String?,
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
        'name': name,
        if (shortName != null) 'shortName': shortName,
        if (logoUrl != null) 'logoUrl': logoUrl,
      };
}
