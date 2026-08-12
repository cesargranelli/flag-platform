import '../enums/competition_status.dart';

class Competition {
  final int id;
  final String name;
  final int organizationId;
  final CompetitionStatus status;

  const Competition({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.status,
  });

  factory Competition.fromJson(Map<String, dynamic> json) => Competition(
        id: json['id'] as int,
        name: json['name'] as String,
        organizationId: json['organizationId'] as int,
        status: CompetitionStatus.fromJson(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'organizationId': organizationId,
        'status': status.toJson(),
      };
}
