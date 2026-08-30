/// Rótulo do agrupamento da estrutura do campeonato (#308).
///
/// Divisões e Grupos têm a mesma dinâmica — muda apenas o label.
enum GroupingType {
  divisions,
  groups;

  static GroupingType fromJson(String value) => switch (value) {
        'DIVISIONS' => GroupingType.divisions,
        'GROUPS' => GroupingType.groups,
        _ => throw FormatException('Tipo de agrupamento desconhecido: $value'),
      };

  static GroupingType? tryFromJson(String? value) {
    if (value == null) return null;
    try {
      return fromJson(value);
    } on FormatException {
      return null;
    }
  }

  String toJson() => switch (this) {
        GroupingType.divisions => 'DIVISIONS',
        GroupingType.groups => 'GROUPS',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        GroupingType.divisions => 'Divisões',
        GroupingType.groups => 'Grupos',
      };
}
