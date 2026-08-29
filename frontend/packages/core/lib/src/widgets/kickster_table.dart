import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tabela no estilo do kit Kickster (issue #441).
///
/// Estilo "classificação" do kit: cabeçalho com fundo `grayFill` e texto w700,
/// células com a primeira coluna em `textPrimary` (w600) e as demais em
/// `textSecondary`, contorno `line` e raio 12. Ícone opcional por linha
/// ([leading]) e linha destacada ([highlightRow]) com fundo `primary` @4%.
class KicksterTable extends StatelessWidget {
  const KicksterTable({
    super.key,
    required this.columns,
    required this.rows,
    this.leading,
    this.highlightRow,
  });

  final List<String> columns;
  final List<List<String>> rows;

  /// Ícone exibido à esquerda de cada linha (paralelo a [rows]).
  final List<IconData>? leading;

  /// Índice da linha a destacar com fundo `primary` @4%.
  final int? highlightRow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          for (var i = 0; i < rows.length; i++) _buildRow(i),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.grayFill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (leading != null) const SizedBox(width: 24),
          for (final column in columns)
            Expanded(
              child: Text(
                column,
                style: const TextStyle(
                  fontSize: 12,
                  height: 20 / 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.06,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = rows[index];
    final highlighted = index == highlightRow;
    return Container(
      color:
          highlighted ? AppColors.primary.withValues(alpha: 0.04) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (leading != null) ...[
            SizedBox(
              width: 24,
              child: index < leading!.length
                  ? Icon(leading![index], size: 16, color: AppColors.primary)
                  : null,
            ),
          ],
          for (var c = 0; c < columns.length; c++)
            Expanded(
              child: Text(
                c < row.length ? row[c] : '',
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  fontWeight: c == 0 ? FontWeight.w600 : FontWeight.w400,
                  color: c == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}