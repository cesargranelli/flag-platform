enum OrganizationStatus {
  active,
  inactive;

  static OrganizationStatus fromJson(String value) => switch (value) {
        'ACTIVE' => OrganizationStatus.active,
        'INACTIVE' => OrganizationStatus.inactive,
        _ => throw FormatException('Status de organização desconhecido: $value'),
      };

  String toJson() => switch (this) {
        OrganizationStatus.active => 'ACTIVE',
        OrganizationStatus.inactive => 'INACTIVE',
      };
}
