/// DTO de resposta do endpoint `GET /api/v1/games/{gameId}/plays`.
///
/// Espelha o record Java `PlayResponse` do backend.
class PlayResponse {
  final String id;
  final String gameId;
  final String teamId;
  final String teamName;
  final String playerName;
  final String? receiverName;
  final String playType; // Código do backend: RUN, PASS, TOUCHDOWN, etc.
  final String? description;
  final int yards;
  final String? quarter;
  final String? time;
  final bool isFirstDown;
  final bool isTouchdown;
  final bool isTurnover;

  const PlayResponse({
    required this.id,
    required this.gameId,
    required this.teamId,
    required this.teamName,
    required this.playerName,
    this.receiverName,
    required this.playType,
    this.description,
    this.yards = 0,
    this.quarter,
    this.time,
    this.isFirstDown = false,
    this.isTouchdown = false,
    this.isTurnover = false,
  });

  factory PlayResponse.fromJson(Map<String, dynamic> json) => PlayResponse(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        teamId: json['teamId'] as String,
        teamName: json['teamName'] as String,
        playerName: json['playerName'] as String,
        receiverName: json['receiverName'] as String?,
        playType: json['playType'] as String,
        description: json['description'] as String?,
        yards: json['yards'] as int? ?? 0,
        quarter: json['quarter'] as String?,
        time: json['time'] as String?,
        isFirstDown: json['isFirstDown'] as bool? ?? false,
        isTouchdown: json['isTouchdown'] as bool? ?? false,
        isTurnover: json['isTurnover'] as bool? ?? false,
      );
}
