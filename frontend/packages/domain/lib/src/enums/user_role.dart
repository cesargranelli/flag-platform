enum UserRole {
  admin,
  organizer,
  mesa;

  static UserRole fromJson(String value) => switch (value) {
        'ADMIN' => UserRole.admin,
        'ORGANIZER' => UserRole.organizer,
        'MESA' => UserRole.mesa,
        _ => throw FormatException('Papel desconhecido: $value'),
      };

  String toJson() => switch (this) {
        UserRole.admin => 'ADMIN',
        UserRole.organizer => 'ORGANIZER',
        UserRole.mesa => 'MESA',
      };

  /// Rótulo amigável em pt-BR.
  String get label => switch (this) {
        UserRole.admin => 'Administrador',
        UserRole.organizer => 'Organizador',
        UserRole.mesa => 'Mesa',
      };
}
