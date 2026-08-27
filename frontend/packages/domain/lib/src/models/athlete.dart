import '../enums/athlete_position.dart';

/// Atleta do Flag Platform.
///
/// Shape de `/api/v1/athletes`.
class Athlete {
  final String id;
  final String name;
  final String? cpf;
  final String? nickname;
  final List<AthletePosition> positions;
  final int? number;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Athlete({
    required this.id,
    required this.name,
    this.cpf,
    this.nickname,
    this.positions = const [],
    this.number,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    // Backend atual expõe `positions` (lista). Fallback para o shape legado
    // (`position` único) quando o campo não vier como lista.
    final rawPositions = json['positions'];
    final List<AthletePosition> positions;
    if (rawPositions is List) {
      positions = rawPositions.whereType<String>().map(AthletePosition.fromJson).toList();
    } else if (json['position'] is String) {
      positions = [AthletePosition.fromJson(json['position'] as String)];
    } else {
      positions = const [];
    }
    return Athlete(
      id: json['id'] as String,
      name: json['name'] as String,
      cpf: json['cpf'] as String?,
      nickname: json['nickname'] as String?,
      positions: positions,
      number: json['number'] as int?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Posição primária (a primeira da lista), quando houver.
  AthletePosition? get primaryPosition =>
      positions.isNotEmpty ? positions.first : null;

  /// Rótulos das posições do atleta unidos por " / " para exibição.
  String get positionsLabel => positions.map((p) => p.label).join(' / ');

  /// Corpo de criação/atualização (`POST/PUT /api/v1/athletes`).
  Map<String, dynamic> toJson() => {
        'name': name,
        if (cpf != null) 'cpf': cpf,
        if (nickname != null) 'nickname': nickname,
        'positions': positions.map((p) => p.toJson()).toList(),
        if (number != null) 'number': number,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}
