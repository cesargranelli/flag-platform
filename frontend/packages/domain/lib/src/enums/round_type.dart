enum RoundType {
  regular,
  playoffs,
  wildcard,
  semifinal,
  finalRound;

  static RoundType fromJson(String value) => switch (value) {
        'REGULAR' => RoundType.regular,
        'PLAYOFFS' => RoundType.playoffs,
        'WILDCARD' => RoundType.wildcard,
        'SEMIFINAL' => RoundType.semifinal,
        'FINAL' => RoundType.finalRound,
        _ => throw FormatException('Tipo de rodada desconhecido: $value'),
      };

  String toJson() => switch (this) {
        RoundType.regular => 'REGULAR',
        RoundType.playoffs => 'PLAYOFFS',
        RoundType.wildcard => 'WILDCARD',
        RoundType.semifinal => 'SEMIFINAL',
        RoundType.finalRound => 'FINAL',
      };

  /// Rótulo amigável em pt-BR para exibição na interface.
  String get label => switch (this) {
        RoundType.regular => 'Regular',
        RoundType.playoffs => 'Playoffs',
        RoundType.wildcard => 'Wildcard',
        RoundType.semifinal => 'Semifinal',
        RoundType.finalRound => 'Final',
      };
}
