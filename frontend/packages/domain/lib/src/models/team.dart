class Team {
  final int id;
  final String name;
  final String abbreviation;
  final String? logoUrl;
  final int categoryId;

  const Team({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.categoryId,
    this.logoUrl,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'] as int,
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
        categoryId: json['categoryId'] as int,
        logoUrl: json['logoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'categoryId': categoryId,
        'logoUrl': logoUrl,
      };
}
