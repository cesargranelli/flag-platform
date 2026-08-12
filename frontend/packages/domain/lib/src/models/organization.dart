class Organization {
  final int id;
  final String name;
  final String slug;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };
}
