import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Título de seção no estilo do kit Kickster (issue #436).
///
/// Usado em listagens como "Ao vivo" / "Próximos": título em escala do tema
/// (`titleMedium` 20/28 semibold) na cor `textPrimary`, com ícone `primary`
/// opcional e ação opcional à direita (ex.: "Ver todos").
class KicksterSectionTitle extends StatelessWidget {
  const KicksterSectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.action,
  });

  final String title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: (Theme.of(context).textTheme.titleMedium ??
                    const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ))
                .copyWith(color: AppColors.textPrimary),
          ),
        ),
        ?action,
      ],
    );
  }
}