/// Divisão de um campeonato (agrupamento de times).
///
/// Opcionalmente vinculada a uma conferência. Shape de `/api/v1/divisions`.
class Division {
  final String id;
  final String competitionId;
  final String? conferenceId;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Division({
    required this.id,
    required this.competitionId,
    this.conferenceId,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  factory Division.fromJson(Map<String, dynamic> json) => Division(
    id: json['id'] as String,
    competitionId: json['competitionId'] as String,
    conferenceId: json['conferenceId'] as String?,
    name: json['name'] as String,
    createdAt: json['createdAt'] is String
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] is String
        ? DateTime.tryParse(json['updatedAt'] as String)
        : null,
  );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/divisions`).
  Map<String, dynamic> toJson() => {
    'competitionId': competitionId,
    'conferenceId': conferenceId,
    'name': name,
  };
}
