enum GameStatus {
  scheduled,
  inProgress,
  finished,
  cancelled;

  static GameStatus fromJson(String value) => switch (value) {
        'SCHEDULED' => GameStatus.scheduled,
        'IN_PROGRESS' => GameStatus.inProgress,
        'FINISHED' => GameStatus.finished,
        'CANCELLED' => GameStatus.cancelled,
        _ => throw FormatException('Status desconhecido: $value'),
      };

  String toJson() => switch (this) {
        GameStatus.scheduled => 'SCHEDULED',
        GameStatus.inProgress => 'IN_PROGRESS',
        GameStatus.finished => 'FINISHED',
        GameStatus.cancelled => 'CANCELLED',
      };

  /// Rótulo amigável em pt-BR para exibição na interface.
  String get label => switch (this) {
        GameStatus.scheduled => 'Agendado',
        GameStatus.inProgress => 'Ao vivo',
        GameStatus.finished => 'Encerrado',
        GameStatus.cancelled => 'Cancelado',
      };
}
