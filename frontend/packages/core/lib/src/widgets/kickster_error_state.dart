import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'kickster_button.dart';

/// Estado de erro no estilo do kit Kickster (issue #441).
///
/// Ícone grande em `danger` (padrão `error_outline`), mensagem `textPrimary`
/// (w600) e botão "Tentar novamente" em `KicksterButton` outline.
class KicksterErrorState extends StatelessWidget {
  const KicksterErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.paragraph.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              KicksterButton(
                label: 'Tentar novamente',
                variant: KicksterButtonVariant.outline,
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}