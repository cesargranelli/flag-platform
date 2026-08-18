enum AgeGroup {
  sub11,
  sub13,
  sub14,
  sub15,
  sub17,
  sub20,
  adult,
  master,
  open;

  static AgeGroup fromJson(String value) => switch (value) {
        'SUB11' => AgeGroup.sub11,
        'SUB13' => AgeGroup.sub13,
        'SUB14' => AgeGroup.sub14,
        'SUB15' => AgeGroup.sub15,
        'SUB17' => AgeGroup.sub17,
        'SUB20' => AgeGroup.sub20,
        'ADULT' => AgeGroup.adult,
        'MASTER' => AgeGroup.master,
        'OPEN' => AgeGroup.open,
        _ => throw FormatException('Faixa etária desconhecida: $value'),
      };

  String toJson() => switch (this) {
        AgeGroup.sub11 => 'SUB11',
        AgeGroup.sub13 => 'SUB13',
        AgeGroup.sub14 => 'SUB14',
        AgeGroup.sub15 => 'SUB15',
        AgeGroup.sub17 => 'SUB17',
        AgeGroup.sub20 => 'SUB20',
        AgeGroup.adult => 'ADULT',
        AgeGroup.master => 'MASTER',
        AgeGroup.open => 'OPEN',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        AgeGroup.sub11 => 'Sub-11',
        AgeGroup.sub13 => 'Sub-13',
        AgeGroup.sub14 => 'Sub-14',
        AgeGroup.sub15 => 'Sub-15',
        AgeGroup.sub17 => 'Sub-17',
        AgeGroup.sub20 => 'Sub-20',
        AgeGroup.adult => 'Adulto',
        AgeGroup.master => 'Master',
        AgeGroup.open => 'Livre',
      };
}
