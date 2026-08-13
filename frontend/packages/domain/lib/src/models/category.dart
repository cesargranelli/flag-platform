/// Categoria de um campeonato.
///
/// Shape público do endpoint de categorias por campeonato: ids são UUID
/// (String) e as datas de auditoria são opcionais.
class Category {
  final String id;
  final String competitionId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.competitionId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        competitionId: json['competitionId'] as String,
        name: json['name'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'competitionId': competitionId,
        'name': name,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
