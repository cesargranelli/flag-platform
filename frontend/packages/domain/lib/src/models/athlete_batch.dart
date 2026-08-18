/// Resultado de uma linha em carga em lote de atletas.
class AthleteBatchLine {
  final int line;
  final String status;
  final String? reason;

  const AthleteBatchLine({
    required this.line,
    required this.status,
    this.reason,
  });

  factory AthleteBatchLine.fromJson(Map<String, dynamic> json) => AthleteBatchLine(
        line: json['line'] as int,
        status: json['status'] as String,
        reason: json['reason'] as String?,
      );
}

/// Resultado agregado de uma carga em lote de atletas.
class AthleteBatchResult {
  final int total;
  final int imported;
  final int skipped;
  final List<AthleteBatchLine> lines;

  const AthleteBatchResult({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.lines,
  });

  factory AthleteBatchResult.fromJson(Map<String, dynamic> json) =>
      AthleteBatchResult(
        total: json['total'] as int,
        imported: json['imported'] as int,
        skipped: json['skipped'] as int,
        lines: ((json['lines'] as List?) ?? const [])
            .map((e) => AthleteBatchLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get valid => lines.where((l) => l.status == 'VALID').length;
  int get invalid => lines.where((l) => l.status == 'INVALID').length;
  int get duplicates =>
      lines.where((l) => l.status == 'DUPLICATE').length;
}
