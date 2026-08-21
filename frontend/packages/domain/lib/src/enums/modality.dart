/// Modalidade de uma competição (valores fixos do contrato da API).
enum Modality {
  flag5x5,
  flag8x8,
  flag9x9,
  fullPads11x11;

  static Modality fromJson(String value) => switch (value) {
        'FLAG_5X5' => Modality.flag5x5,
        'FLAG_8X8' => Modality.flag8x8,
        'FLAG_9X9' => Modality.flag9x9,
        'FULL_PADS_11X11' => Modality.fullPads11x11,
        _ => throw FormatException('Modalidade desconhecida: $value'),
      };

  String toJson() => switch (this) {
        Modality.flag5x5 => 'FLAG_5X5',
        Modality.flag8x8 => 'FLAG_8X8',
        Modality.flag9x9 => 'FLAG_9X9',
        Modality.fullPads11x11 => 'FULL_PADS_11X11',
      };

  /// Rótulo amigável.
  String get label => switch (this) {
        Modality.flag5x5 => 'Flag 5x5',
        Modality.flag8x8 => 'Flag 8x8',
        Modality.flag9x9 => 'Flag 9x9',
        Modality.fullPads11x11 => 'Full Pads 11x11',
      };
}
