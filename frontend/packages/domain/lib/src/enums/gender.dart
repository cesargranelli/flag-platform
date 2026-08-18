enum Gender {
  male,
  female,
  mixed;

  static Gender fromJson(String value) => switch (value) {
        'MALE' => Gender.male,
        'FEMALE' => Gender.female,
        'MIXED' => Gender.mixed,
        _ => throw FormatException('Gênero desconhecido: $value'),
      };

  String toJson() => switch (this) {
        Gender.male => 'MALE',
        Gender.female => 'FEMALE',
        Gender.mixed => 'MIXED',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        Gender.male => 'Masculino',
        Gender.female => 'Feminino',
        Gender.mixed => 'Misto',
      };
}
