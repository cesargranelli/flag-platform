class Round {
  final int id;
  final int number;
  final String name;
  final int categoryId;

  const Round({
    required this.id,
    required this.number,
    required this.name,
    required this.categoryId,
  });

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        id: json['id'] as int,
        number: json['number'] as int,
        name: json['name'] as String,
        categoryId: json['categoryId'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'categoryId': categoryId,
      };
}
