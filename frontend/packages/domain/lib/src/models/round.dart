import '../enums/round_type.dart';

/// Rodada de uma categoria.
///
/// Shape de `/api/v1/rounds`.
class Round {
  final String id;
  final String categoryId;
  final int number;
  final String name;
  final RoundType type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Round({
    required this.id,
    required this.categoryId,
    required this.number,
    required this.name,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        id: json['id'] as String,
        categoryId: json['categoryId'] as String,
        number: json['number'] as int,
        name: json['name'] as String,
        type: RoundType.fromJson(json['type'] as String),
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/rounds`).
  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'number': number,
        'name': name,
        'type': type.toJson(),
      };
}
