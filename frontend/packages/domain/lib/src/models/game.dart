import '../enums/game_status.dart';

/// Jogo do calendário de uma competição.
///
/// Shape público do endpoint de calendário:
/// times e campo chegam como nomes (exibição direta) e a data em ISO-8601.
class Game {
  final String id;
  final String roundId;
  final String? competitionId;
  final String? homeTeamId;
  final String? awayTeamId;
  final int? roundNumber;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? venueId;
  final String? venueName;
  final String? venueAddress;
  final String? venueMapsUrl;
  final DateTime scheduledAt;
  final GameStatus status;
  final int? homeScore;
  final int? awayScore;

  const Game({
    required this.id,
    required this.roundId,
    required this.scheduledAt,
    required this.status,
    this.competitionId,
    this.homeTeamId,
    this.awayTeamId,
    this.roundNumber,
    this.homeTeamName,
    this.awayTeamName,
    this.venueId,
    this.venueName,
    this.venueAddress,
    this.venueMapsUrl,
    this.homeScore,
    this.awayScore,
  });

  factory Game.fromJson(Map<String, dynamic> json) => Game(
    id: json['id'] as String,
    roundId: json['roundId'] as String,
    competitionId: json['competitionId'] as String?,
    homeTeamId: json['homeTeamId'] as String?,
    awayTeamId: json['awayTeamId'] as String?,
    roundNumber: json['roundNumber'] as int?,
    homeTeamName: json['homeTeamName'] as String?,
    awayTeamName: json['awayTeamName'] as String?,
    venueId: json['venueId'] as String?,
    venueName: json['venueName'] as String?,
    venueAddress: json['venueAddress'] as String?,
    venueMapsUrl: json['venueMapsUrl'] as String?,
    scheduledAt: DateTime.parse(json['scheduledAt'] as String),
    status: GameStatus.fromJson(json['status'] as String),
    homeScore: json['homeScore'] as int?,
    awayScore: json['awayScore'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roundId': roundId,
    if (competitionId != null) 'competitionId': competitionId,
    if (homeTeamId != null) 'homeTeamId': homeTeamId,
    if (awayTeamId != null) 'awayTeamId': awayTeamId,
    if (roundNumber != null) 'roundNumber': roundNumber,
    if (homeTeamName != null) 'homeTeamName': homeTeamName,
    if (awayTeamName != null) 'awayTeamName': awayTeamName,
    if (venueId != null) 'venueId': venueId,
    if (venueName != null) 'venueName': venueName,
    if (venueAddress != null) 'venueAddress': venueAddress,
    if (venueMapsUrl != null) 'venueMapsUrl': venueMapsUrl,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status.toJson(),
    if (homeScore != null) 'homeScore': homeScore,
    if (awayScore != null) 'awayScore': awayScore,
  };
}
