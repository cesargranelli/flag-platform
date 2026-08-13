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
}
