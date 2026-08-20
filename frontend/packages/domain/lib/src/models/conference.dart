/// Conferência de uma categoria (agrupamento opcional de divisões).
///
/// Shape de `/api/v1/conferences`.
class Conference {
  final String id;
  final String categoryId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conference({
    required this.id,
    required this.categoryId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Conference.fromJson(Map<String, dynamic> json) => Conference(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/conferences`).
  Map<String, dynamic> toJson() => {
        'name': name,
      };
}