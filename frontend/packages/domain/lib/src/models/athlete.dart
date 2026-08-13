import '../enums/athlete_position.dart';

/// Atleta do Flag Platform.
///
/// Shape de `/api/v1/athletes`.
class Athlete {
  final String id;
  final String name;
  final String? nickname;
  final AthletePosition? position;
  final int? number;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Athlete({
    required this.id,
    required this.name,
    this.nickname,
    this.position,
    this.number,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete(
        id: json['id'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        position: json['position'] is String
            ? AthletePosition.fromJson(json['position'] as String)
            : null,
        number: json['number'] as int?,
        photoUrl: json['photoUrl'] as String?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/athletes`).
  Map<String, dynamic> toJson() => {
        'name': name,
        if (nickname != null) 'nickname': nickname,
        if (position != null) 'position': position!.toJson(),
        if (number != null) 'number': number,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}
