/// Resultado de uma linha em carga em lote de elenco.
class RosterBatchLine {
  final int line;
  final String status;
  final String? reason;

  const RosterBatchLine({
    required this.line,
    required this.status,
    this.reason,
  });

  factory RosterBatchLine.fromJson(Map<String, dynamic> json) => RosterBatchLine(
        line: json['line'] as int,
        status: json['status'] as String,
        reason: json['reason'] as String?,
      );
}

/// Resultado agregado de uma carga em lote de elenco.
class RosterBatchResult {
  final int total;
  final int imported;
  final int skipped;
  final List<RosterBatchLine> lines;

  const RosterBatchResult({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.lines,
  });

  factory RosterBatchResult.fromJson(Map<String, dynamic> json) =>
      RosterBatchResult(
        total: json['total'] as int,
        imported: json['imported'] as int,
        skipped: json['skipped'] as int,
        lines: ((json['lines'] as List?) ?? const [])
            .map((e) => RosterBatchLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
