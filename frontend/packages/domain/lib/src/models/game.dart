import '../enums/game_status.dart';

class Game {
  final int id;
  final int roundId;
  final int homeTeamId;
  final int awayTeamId;
  final int? venueId;
  final DateTime scheduledAt;
  final GameStatus status;
  final int? homeScore;
  final int? awayScore;

  const Game({
    required this.id,
    required this.roundId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.scheduledAt,
    required this.status,
    this.venueId,
    this.homeScore,
    this.awayScore,
  });

  factory Game.fromJson(Map<String, dynamic> json) => Game(
        id: json['id'] as int,
        roundId: json['roundId'] as int,
        homeTeamId: json['homeTeamId'] as int,
        awayTeamId: json['awayTeamId'] as int,
        venueId: json['venueId'] as int?,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        status: GameStatus.fromJson(json['status'] as String),
        homeScore: json['homeScore'] as int?,
        awayScore: json['awayScore'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roundId': roundId,
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'venueId': venueId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'status': status.toJson(),
        'homeScore': homeScore,
        'awayScore': awayScore,
      };
}
