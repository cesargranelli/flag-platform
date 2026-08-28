/// DTO de resposta do endpoint `GET /api/v1/games/live`.
///
/// Inclui todos os campos de `GameSummaryResponse` mais metadados de competição
/// (modalidade, gênero) para que o frontend possa exibir jogos cross-competition
/// sem chamadas adicionais.
class LiveGameResponse {
  final String id;
  final String? roundId;
  final int? roundNumber;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? venueId;
  final String? venueName;
  final String? venueAddress;
  final String? venueMapsUrl;
  final DateTime scheduledAt;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final String? competitionId;
  final String? competitionName;
  final String? modality;
  final String? gender;

  const LiveGameResponse({
    required this.id,
    this.roundId,
    this.roundNumber,
    this.homeTeamName,
    this.awayTeamName,
    this.venueId,
    this.venueName,
    this.venueAddress,
    this.venueMapsUrl,
    required this.scheduledAt,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.competitionId,
    this.competitionName,
    this.modality,
    this.gender,
  });

  factory LiveGameResponse.fromJson(Map<String, dynamic> json) =>
      LiveGameResponse(
        id: json['id'] as String,
        roundId: json['roundId'] as String?,
        roundNumber: json['roundNumber'] as int?,
        homeTeamName: json['homeTeamName'] as String?,
        awayTeamName: json['awayTeamName'] as String?,
        venueId: json['venueId'] as String?,
        venueName: json['venueName'] as String?,
        venueAddress: json['venueAddress'] as String?,
        venueMapsUrl: json['venueMapsUrl'] as String?,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        status: json['status'] as String,
        homeScore: json['homeScore'] as int?,
        awayScore: json['awayScore'] as int?,
        competitionId: json['competitionId'] as String?,
        competitionName: json['competitionName'] as String?,
        modality: json['modality'] as String?,
        gender: json['gender'] as String?,
      );
}
