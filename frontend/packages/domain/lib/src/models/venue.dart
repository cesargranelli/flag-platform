class Venue {
  final int id;
  final String name;
  final String? address;
  final String? mapUrl;

  const Venue({
    required this.id,
    required this.name,
    this.address,
    this.mapUrl,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String?,
        mapUrl: json['mapUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'mapUrl': mapUrl,
      };
}
