/// Posição de um time na tabela de classificação de uma categoria.
///
/// Shape público do endpoint de classificação: ids são UUID (String) e o nome
/// do time chega preenchido para exibição direta.
class Standing {
  final int position;
  final String teamId;
  final String? teamName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const Standing({
    required this.position,
    required this.teamId,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    this.teamName,
  });

  factory Standing.fromJson(Map<String, dynamic> json) => Standing(
        position: json['position'] as int,
        teamId: json['teamId'] as String,
        teamName: json['teamName'] as String?,
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
        'position': position,
        'teamId': teamId,
        if (teamName != null) 'teamName': teamName,
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
