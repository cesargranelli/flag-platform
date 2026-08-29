import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Card de módulo no estilo do kit Kickster (issues #433/#436/#439).
///
/// Raio 12, fundo `surface` branco com elevação sutil e contorno `line`
/// (Line do kit — borda clara de 1px). Interação via `Card` + `InkWell` com
/// a tinta padrão do tema (#300) — sem hover/splash customizados.
///
/// Dois modos de layout:
/// - **Tile** (padrão, sem [subtitle] e sem [trailing]): ícone grande em
///   `primary` sobre um círculo `primary` @10% centralizado acima do título —
///   usado na home (#433).
/// - **Linha** (com [subtitle] e/ou [trailing]): ícone à esquerda + coluna
///   título/subtítulo + widget de apoio à direita — usado nas listagens de
///   módulos do admin (org, campeonato, campo, time, atleta).
class KicksterCard extends StatelessWidget {
  const KicksterCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;

  /// Linha secundária opcional (ex.: nome legal, endereço, contagem).
  final String? subtitle;

  /// Widget de apoio opcional à direita (ex.: menu de ações, badges).
  final Widget? trailing;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDetails = subtitle != null || trailing != null;
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: hasDetails ? _buildRowLayout() : _buildTileLayout(),
      ),
    );
  }

  /// Layout em linha (listagens): ícone à esquerda, título/subtítulo à
  /// direita e o [trailing] na ponta.
  Widget _buildRowLayout() {
    // Subtítulo opcional: widget nulo é omitido pelo elemento null-aware (?).
    final subtitleWidget = subtitle == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                ?subtitleWidget,
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  /// Layout em tile (home #433): ícone grande centralizado acima do título.
  Widget _buildTileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}