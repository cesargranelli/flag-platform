enum GameStatus {
  scheduled,
  open,
  inProgress,
  conference,
  finished,
  cancelled;

  static GameStatus fromJson(String value) => switch (value) {
        'SCHEDULED' => GameStatus.scheduled,
        'OPEN' => GameStatus.open,
        'IN_PROGRESS' => GameStatus.inProgress,
        'CONFERENCE' => GameStatus.conference,
        'FINISHED' => GameStatus.finished,
        'CANCELLED' => GameStatus.cancelled,
        _ => throw FormatException('Status desconhecido: $value'),
      };

  String toJson() => switch (this) {
        GameStatus.scheduled => 'SCHEDULED',
        GameStatus.open => 'OPEN',
        GameStatus.inProgress => 'IN_PROGRESS',
        GameStatus.conference => 'CONFERENCE',
        GameStatus.finished => 'FINISHED',
        GameStatus.cancelled => 'CANCELLED',
      };

  /// Rótulo amigável em pt-BR para exibição na interface.
  String get label => switch (this) {
        GameStatus.scheduled => 'Agendado',
        GameStatus.open => 'Abertura',
        GameStatus.inProgress => 'Ao vivo',
        GameStatus.conference => 'Conferência',
        GameStatus.finished => 'Encerrado',
        GameStatus.cancelled => 'Cancelado',
      };
}
