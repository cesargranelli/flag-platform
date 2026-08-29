import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Badge de status no estilo do kit Kickster (issue #436).
///
/// Fundo `color` @12%, texto/ícone na cor do badge e raio 10. Usado para
/// status semânticos (Agendado, Ao vivo, Encerrado, Cancelado) e qualquer
/// etiqueta colorida.
///
/// **Regra de contraste (#294/#431)**: conteúdo sobre `warning` (#FACC15)
/// nunca é branco — texto/ícone usam `textPrimary` escuro (#171725).
class KicksterBadge extends StatelessWidget {
  const KicksterBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Conteúdo escuro sobre warning (contraste AA); demais cores seguem a
    // própria cor do badge sobre fundo claro @12%.
    final foreground =
        color == AppColors.warning ? AppColors.textPrimary : color;

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                height: 20 / 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}