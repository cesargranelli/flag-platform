import '../enums/check_in_status.dart';

/// Check-in de um atleta em um jogo.
///
/// Shape de `GET /api/v1/games/{id}/checkin` e `POST /checkin/{athleteId}`.
class CheckIn {
  final String gameId;
  final String teamId;
  final String? teamName;
  final String athleteId;
  final String athleteName;
  final String? athleteNickname;
  final int? number;
  final int? athleteNumber;
  final int? matchNumber;
  final String? position;
  final CheckInStatus? status;
  final String? validatedBy;
  final DateTime? validatedAt;

  const CheckIn({
    required this.gameId,
    required this.teamId,
    required this.athleteId,
    required this.athleteName,
    this.teamName,
    this.athleteNickname,
    this.number,
    this.athleteNumber,
    this.matchNumber,
    this.position,
    this.status,
    this.validatedBy,
    this.validatedAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        gameId: json['gameId'] as String,
        teamId: json['teamId'] as String,
        teamName: json['teamName'] as String?,
        athleteId: json['athleteId'] as String,
        athleteName: json['athleteName'] as String,
        athleteNickname: json['athleteNickname'] as String?,
        number: json['number'] as int?,
        athleteNumber: json['athleteNumber'] as int?,
        matchNumber: json['matchNumber'] as int?,
        position: json['position'] as String?,
        status: json['status'] is String
            ? CheckInStatus.fromJson(json['status'] as String)
            : null,
        validatedBy: json['validatedBy'] as String?,
        validatedAt: json['validatedAt'] is String
            ? DateTime.tryParse(json['validatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'teamId': teamId,
        'athleteId': athleteId,
        'athleteName': athleteName,
        'status': status?.toJson(),
      };
}
