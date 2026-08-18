import '../enums/age_group.dart';
import '../enums/gender.dart';

/// Categoria de um campeonato.
///
/// Shape público do endpoint de categorias por campeonato: ids são UUID
/// (String) e as datas de auditoria são opcionais. A categoria é a combinação
/// estruturada de modalidade + gênero + faixa etária.
class Category {
  final String id;
  final String competitionId;
  final String modalityId;
  final String? modalityName;
  final String? modalityFormat;
  final Gender gender;
  final AgeGroup ageGroup;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.competitionId,
    required this.modalityId,
    required this.gender,
    required this.ageGroup,
    required this.name,
    this.modalityName,
    this.modalityFormat,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        competitionId: json['competitionId'] as String,
        modalityId: json['modalityId'] as String,
        modalityName: json['modalityName'] as String?,
        modalityFormat: json['modalityFormat'] as String?,
        gender: Gender.fromJson(json['gender'] as String),
        ageGroup: AgeGroup.fromJson(json['ageGroup'] as String),
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
        'modalityId': modalityId,
        'modalityName': modalityName,
        'modalityFormat': modalityFormat,
        'gender': gender.toJson(),
        'ageGroup': ageGroup.toJson(),
        'name': name,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
