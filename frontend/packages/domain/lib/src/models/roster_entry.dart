import '../enums/athlete_position.dart';

/// Entrada do elenco de um time.
///
/// Shape de `GET /api/v1/teams/{teamId}/roster`.
class RosterEntry {
  final String id;
  final String teamId;
  final String athleteId;
  final String athleteName;
  final String? athleteNickname;
  final String? nickname;
  final AthletePosition? position;
  final int? number;
  final String? photoUrl;
  final String status;
  final DateTime? createdAt;

  const RosterEntry({
    required this.id,
    required this.teamId,
    required this.athleteId,
    required this.athleteName,
    required this.status,
    this.athleteNickname,
    this.nickname,
    this.position,
    this.number,
    this.photoUrl,
    this.createdAt,
  });

  factory RosterEntry.fromJson(Map<String, dynamic> json) => RosterEntry(
        id: json['id'] as String,
        teamId: json['teamId'] as String,
        athleteId: json['athleteId'] as String,
        athleteName: json['athleteName'] as String,
        athleteNickname: json['athleteNickname'] as String?,
        nickname: json['nickname'] as String?,
        position: json['position'] is String
            ? AthletePosition.fromJson(json['position'] as String)
            : null,
        number: json['number'] as int?,
        photoUrl: json['photoUrl'] as String?,
        status: json['status'] as String,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamId': teamId,
        'athleteId': athleteId,
        'athleteName': athleteName,
        'status': status,
      };
}
