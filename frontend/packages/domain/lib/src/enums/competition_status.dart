enum CompetitionStatus {
  draft,
  published,
  finished;

  static CompetitionStatus fromJson(String value) => switch (value) {
        'DRAFT' => CompetitionStatus.draft,
        'PUBLISHED' => CompetitionStatus.published,
        'FINISHED' => CompetitionStatus.finished,
        _ => throw FormatException('Status desconhecido: $value'),
      };

  String toJson() => switch (this) {
        CompetitionStatus.draft => 'DRAFT',
        CompetitionStatus.published => 'PUBLISHED',
        CompetitionStatus.finished => 'FINISHED',
      };
}
