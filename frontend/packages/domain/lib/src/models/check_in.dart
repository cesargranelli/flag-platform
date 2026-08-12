import '../enums/check_in_status.dart';

class CheckIn {
  final int gameId;
  final int teamId;
  final int athleteId;
  final CheckInStatus status;
  final String? validatedBy;
  final DateTime? validatedAt;

  const CheckIn({
    required this.gameId,
    required this.teamId,
    required this.athleteId,
    required this.status,
    this.validatedBy,
    this.validatedAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        gameId: json['gameId'] as int,
        teamId: json['teamId'] as int,
        athleteId: json['athleteId'] as int,
        status: CheckInStatus.fromJson(json['status'] as String),
        validatedBy: json['validatedBy'] as String?,
        validatedAt: json['validatedAt'] != null
            ? DateTime.parse(json['validatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'teamId': teamId,
        'athleteId': athleteId,
        'status': status.toJson(),
        'validatedBy': validatedBy,
        'validatedAt': validatedAt?.toIso8601String(),
      };
}
