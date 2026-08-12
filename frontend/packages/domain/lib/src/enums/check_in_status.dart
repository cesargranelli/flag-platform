enum CheckInStatus {
  pending,
  present,
  validated,
  noShow,
  notRegistered;

  static CheckInStatus fromJson(String value) => switch (value) {
        'PENDING' => CheckInStatus.pending,
        'PRESENT' => CheckInStatus.present,
        'VALIDATED' => CheckInStatus.validated,
        'NO_SHOW' => CheckInStatus.noShow,
        'NOT_REGISTERED' => CheckInStatus.notRegistered,
        _ => throw FormatException('Status desconhecido: $value'),
      };

  String toJson() => switch (this) {
        CheckInStatus.pending => 'PENDING',
        CheckInStatus.present => 'PRESENT',
        CheckInStatus.validated => 'VALIDATED',
        CheckInStatus.noShow => 'NO_SHOW',
        CheckInStatus.notRegistered => 'NOT_REGISTERED',
      };
}
