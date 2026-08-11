class TeamRoster {
  final int teamId;
  final int athleteId;
  final String status;

  const TeamRoster({
    required this.teamId,
    required this.athleteId,
    required this.status,
  });

  factory TeamRoster.fromJson(Map<String, dynamic> json) => TeamRoster(
        teamId: json['teamId'] as int,
        athleteId: json['athleteId'] as int,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'athleteId': athleteId,
        'status': status,
      };
}
