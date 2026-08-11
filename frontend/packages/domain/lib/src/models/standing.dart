class Standing {
  final int teamId;
  final int position;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const Standing({
    required this.teamId,
    required this.position,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory Standing.fromJson(Map<String, dynamic> json) => Standing(
        teamId: json['teamId'] as int,
        position: json['position'] as int,
        played: json['played'] as int,
        wins: json['wins'] as int,
        draws: json['draws'] as int,
        losses: json['losses'] as int,
        goalsFor: json['goalsFor'] as int,
        goalsAgainst: json['goalsAgainst'] as int,
        goalDifference: json['goalDifference'] as int,
        points: json['points'] as int,
      );

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'position': position,
        'played': played,
        'wins': wins,
        'draws': draws,
        'losses': losses,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'goalDifference': goalDifference,
        'points': points,
      };
}
