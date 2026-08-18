/// Resultado de uma linha em carga em lote de jogos.
class GameBatchLine {
  final int line;
  final String status;
  final String? reason;

  const GameBatchLine({
    required this.line,
    required this.status,
    this.reason,
  });

  factory GameBatchLine.fromJson(Map<String, dynamic> json) => GameBatchLine(
        line: json['line'] as int,
        status: json['status'] as String,
        reason: json['reason'] as String?,
      );
}

/// Resultado agregado de uma carga em lote de jogos.
class GameBatchResult {
  final int total;
  final int imported;
  final int skipped;
  final List<GameBatchLine> lines;

  const GameBatchResult({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.lines,
  });

  factory GameBatchResult.fromJson(Map<String, dynamic> json) => GameBatchResult(
        total: json['total'] as int,
        imported: json['imported'] as int,
        skipped: json['skipped'] as int,
        lines: ((json['lines'] as List?) ?? const [])
            .map((e) => GameBatchLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
