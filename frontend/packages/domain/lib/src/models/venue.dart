/// Campo de jogo (venue) do Flag Platform.
///
/// Shape de `/api/v1/venues`.
class Venue {
  final String id;
  final String organizationId;
  final String name;
  final String? address;
  final String? mapsUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Venue({
    required this.id,
    required this.organizationId,
    required this.name,
    this.address,
    this.mapsUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) => Venue(
        id: json['id'] as String,
        organizationId: json['organizationId'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        mapsUrl: json['mapsUrl'] as String?,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] is String
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/venues`).
  Map<String, dynamic> toJson() => {
        'organizationId': organizationId,
        'name': name,
        if (address != null) 'address': address,
        if (mapsUrl != null) 'mapsUrl': mapsUrl,
      };
}
