enum OrganizationType {
  federation,
  league,
  association,
  university,
  club,
  other;

  static OrganizationType fromJson(String value) => switch (value) {
        'FEDERATION' => OrganizationType.federation,
        'LEAGUE' => OrganizationType.league,
        'ASSOCIATION' => OrganizationType.association,
        'UNIVERSITY' => OrganizationType.university,
        'CLUB' => OrganizationType.club,
        'OTHER' => OrganizationType.other,
        _ => throw FormatException('Tipo de organização desconhecido: $value'),
      };

  String toJson() => switch (this) {
        OrganizationType.federation => 'FEDERATION',
        OrganizationType.league => 'LEAGUE',
        OrganizationType.association => 'ASSOCIATION',
        OrganizationType.university => 'UNIVERSITY',
        OrganizationType.club => 'CLUB',
        OrganizationType.other => 'OTHER',
      };

  /// Nome amigável em português para exibição.
  String get label => switch (this) {
        OrganizationType.federation => 'Federação',
        OrganizationType.league => 'Liga',
        OrganizationType.association => 'Associação',
        OrganizationType.university => 'Universitário',
        OrganizationType.club => 'Clube',
        OrganizationType.other => 'Outro',
      };
}
