/// Evento de pontuação de um jogo.
///
/// Shape de `GET /api/v1/games/{id}/score/events`.
class ScoreEvent {
  final String id;
  final String gameId;
  final String teamId;
  final DateTime? createdAt;

  const ScoreEvent({
    required this.id,
    required this.gameId,
    required this.teamId,
    this.createdAt,
  });

  factory ScoreEvent.fromJson(Map<String, dynamic> json) => ScoreEvent(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        teamId: json['teamId'] as String,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'teamId': teamId,
      };
}
