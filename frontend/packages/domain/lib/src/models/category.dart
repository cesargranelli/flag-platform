class Category {
  final int id;
  final String name;
  final int competitionId;

  const Category({
    required this.id,
    required this.name,
    required this.competitionId,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        competitionId: json['competitionId'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'competitionId': competitionId,
      };
}
