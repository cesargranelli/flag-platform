class Athlete {
  final int id;
  final String name;
  final String? nickname;
  final String? position;
  final int? number;
  final String? photoUrl;

  const Athlete({
    required this.id,
    required this.name,
    this.nickname,
    this.position,
    this.number,
    this.photoUrl,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete(
        id: json['id'] as int,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        position: json['position'] as String?,
        number: json['number'] as int?,
        photoUrl: json['photoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'position': position,
        'number': number,
        'photoUrl': photoUrl,
      };
}
