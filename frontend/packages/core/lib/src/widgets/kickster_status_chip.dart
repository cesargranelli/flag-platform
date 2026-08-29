import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Variante visual do [KicksterStatusChip].
enum KicksterStatusChipType { success, pending, refund, failed, unpaid }

/// Chip de status no estilo do kit Kickster (issue #449).
///
/// Medidas do Figma (Element 23:169): raio **4**, altura **28px**, padding
/// horizontal 10. Fundo por variante (tokens `chip*Bg`) e texto em tom
/// escuro da mesma cor (tokens `chip*Fg`), mantendo contraste adequado
/// sobre os fundos claros (WCAG AA).
class KicksterStatusChip extends StatelessWidget {
  const KicksterStatusChip({
    super.key,
    required this.status,
    required this.label,
  });

  /// Variante visual (define as cores de fundo e texto).
  final KicksterStatusChipType status;

  /// Rótulo exibido no chip.
  final String label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      KicksterStatusChipType.success => (
          AppColors.chipSuccessBg,
          AppColors.chipSuccessFg,
        ),
      KicksterStatusChipType.pending => (
          AppColors.chipPendingBg,
          AppColors.chipPendingFg,
        ),
      KicksterStatusChipType.refund => (
          AppColors.chipRefundBg,
          AppColors.chipRefundFg,
        ),
      KicksterStatusChipType.failed => (
          AppColors.chipFailedBg,
          AppColors.chipFailedFg,
        ),
      KicksterStatusChipType.unpaid => (
          AppColors.chipUnpaidBg,
          AppColors.chipUnpaidFg,
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: AppTextStyles.fieldLabel.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}