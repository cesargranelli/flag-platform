import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card de conteúdo padronizado das telas de detalhe (#328).
///
/// Uniformiza os `_infoCard` duplicados de `competition_detail_screen` e
/// `organization_detail_screen`: `Card` sem margem (`margin: EdgeInsets.zero`),
/// altura mínima padrão 144, título `titleSmall` (14/24 w700) e conteúdo em
/// coluna alinhada à esquerda, com gap 12 entre título e linhas. As linhas
/// são dadas pelos helpers [AppInfoRow]/[AppInfoColorRow] (ou qualquer widget).
///
/// [title] é opcional (issue #445): quando nulo o card mostra apenas o
/// conteúdo (sem cabeçalho) e não aplica a altura mínima — usado nas telas
/// de detalhe cujo título de seção é redundante com a navegação por sessões.
///
/// Largura máxima é controlada pelo chamador via `AppLayout.detail` (720).
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    this.title,
    required this.children,
    this.minHeight = 144,
    this.padding = const EdgeInsets.all(16),
    this.icon,
  });

  final String? title;
  final List<Widget> children;
  final double? minHeight;
  final EdgeInsetsGeometry padding;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null;
    final titleStyle =
        Theme.of(context).textTheme.titleSmall ??
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w700);
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        constraints: BoxConstraints(
          minHeight: hasTitle ? (minHeight ?? 0) : 0,
        ),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasTitle) ...[
              if (icon != null)
                Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(title!, style: titleStyle),
                  ],
                )
              else
                Text(title!, style: titleStyle),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Linha de metadado do card de conteúdo: rótulo fixo (120px/13px
/// `textSecondary`) + valor expandido (14px) (#328).
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// Linha de cor do card de conteúdo (detalhe de organização): swatch
/// arredondado 18×18 (raio 4) preenchido + valor hex legível (#328).
///
/// Aceita o hex já parseado via [color]; se omitido, interpreta [hex]
/// nas formas `#RRGGBB` ou `RRGGBB`.
class AppInfoColorRow extends StatelessWidget {
  const AppInfoColorRow({
    super.key,
    required this.label,
    required this.hex,
    this.color,
  });

  final String label;
  final String hex;
  final Color? color;

  Color? _parseHex(String? value) {
    if (value == null || value.isEmpty) return null;
    final clean = value.replaceAll('#', '').trim();
    final parsed = int.tryParse('FF$clean', radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final swatch = color ?? _parseHex(hex);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: swatch ?? Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            hex.toUpperCase(),
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}
