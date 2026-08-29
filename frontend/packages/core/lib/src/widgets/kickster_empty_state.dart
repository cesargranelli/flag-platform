import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Estado vazio no estilo do kit Kickster (issue #441).
///
/// Layout centralizado: quadro `primary` @8% com raio 28 e ícone grande em
/// `primary` @40%, mensagem `textPrimary` (w600) e descrição opcional em
/// `textSecondary`. Ação opcional abaixo (ex.: botão primário).
class KicksterEmptyState extends StatelessWidget {
  const KicksterEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.description,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.paragraph.copyWith(color: AppColors.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}