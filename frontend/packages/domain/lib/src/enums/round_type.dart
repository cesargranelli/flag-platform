enum RoundType {
  regular,
  playoffs;

  static RoundType fromJson(String value) => switch (value) {
        'REGULAR' => RoundType.regular,
        'PLAYOFFS' => RoundType.playoffs,
        _ => throw FormatException('Tipo de rodada desconhecido: $value'),
      };

  String toJson() => switch (this) {
        RoundType.regular => 'REGULAR',
        RoundType.playoffs => 'PLAYOFFS',
      };
}
