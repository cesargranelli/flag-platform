enum AthletePosition {
  qb,
  rb,
  wr,
  te,
  c,
  dl,
  lb,
  db,
  k,
  p;

  static AthletePosition fromJson(String value) => switch (value) {
        'QB' => AthletePosition.qb,
        'RB' => AthletePosition.rb,
        'WR' => AthletePosition.wr,
        'TE' => AthletePosition.te,
        'C' => AthletePosition.c,
        'DL' => AthletePosition.dl,
        'LB' => AthletePosition.lb,
        'DB' => AthletePosition.db,
        'K' => AthletePosition.k,
        'P' => AthletePosition.p,
        _ => throw FormatException('Posição desconhecida: $value'),
      };

  String toJson() => switch (this) {
        AthletePosition.qb => 'QB',
        AthletePosition.rb => 'RB',
        AthletePosition.wr => 'WR',
        AthletePosition.te => 'TE',
        AthletePosition.c => 'C',
        AthletePosition.dl => 'DL',
        AthletePosition.lb => 'LB',
        AthletePosition.db => 'DB',
        AthletePosition.k => 'K',
        AthletePosition.p => 'P',
      };

  /// Rótulo amigável em pt-BR para exibição na interface.
  String get label => switch (this) {
        AthletePosition.qb => 'Quarterback',
        AthletePosition.rb => 'Running Back',
        AthletePosition.wr => 'Wide Receiver',
        AthletePosition.te => 'Tight End',
        AthletePosition.c => 'Center',
        AthletePosition.dl => 'Defensive Line',
        AthletePosition.lb => 'Linebacker',
        AthletePosition.db => 'Defensive Back',
        AthletePosition.k => 'Kicker',
        AthletePosition.p => 'Punter',
      };
}
