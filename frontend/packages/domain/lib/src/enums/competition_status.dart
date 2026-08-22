enum CompetitionStatus {
  draft,
  published,
  finished,
  disabled;

  static CompetitionStatus fromJson(String value) => switch (value) {
        'DRAFT' => CompetitionStatus.draft,
        'PUBLISHED' => CompetitionStatus.published,
        'FINISHED' => CompetitionStatus.finished,
        'DISABLED' => CompetitionStatus.disabled,
        _ => throw FormatException('Status desconhecido: $value'),
      };

  String toJson() => switch (this) {
        CompetitionStatus.draft => 'DRAFT',
        CompetitionStatus.published => 'PUBLISHED',
        CompetitionStatus.finished => 'FINISHED',
        CompetitionStatus.disabled => 'DISABLED',
      };

  /// Nome amigável em português para exibição.
  String get label => switch (this) {
        CompetitionStatus.draft => 'Rascunho',
        CompetitionStatus.published => 'Publicado',
        CompetitionStatus.finished => 'Encerrado',
        CompetitionStatus.disabled => 'Desativado',
      };
}
