/// Modalidade de uma categoria (ex.: Flag 5x5, Full Pads 11x11).
///
/// Catálogo público (endpoint GET /api/v1/modalities).
class Modality {
  final String id;
  final String name;
  final String format;
  final String contactType;
  final int playersPerTeam;

  const Modality({
    required this.id,
    required this.name,
    required this.format,
    required this.contactType,
    required this.playersPerTeam,
  });

  factory Modality.fromJson(Map<String, dynamic> json) => Modality(
        id: json['id'] as String,
        name: json['name'] as String,
        format: json['format'] as String,
        contactType: json['contactType'] as String,
        playersPerTeam: json['playersPerTeam'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'format': format,
        'contactType': contactType,
        'playersPerTeam': playersPerTeam,
      };

  /// Rótulo amigável (ex.: "Flag Football 5x5").
  String get label => '$name $format'.trim();
}
