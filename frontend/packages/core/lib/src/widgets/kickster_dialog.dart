import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'kickster_button.dart';

/// Diálogo de confirmação no estilo do kit Kickster (issue #441).
///
/// Raio 16 e fundo `surface`, com botões do kit: confirmar = `KicksterButton`
/// primário (ou em `danger` quando [danger] é `true`) e cancelar = variante
/// text. Fecha com `Navigator.pop(true/false)` — use os callbacks
/// ([onConfirm]/[onCancel]) **ou** o retorno de [showKicksterConfirm], não
/// os dois ao mesmo tempo (evita ação duplicada).
class KicksterDialog extends StatelessWidget {
  const KicksterDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.danger = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Quando `true`, o botão de confirmar usa a cor `danger`.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        content,
        style: AppTextStyles.paragraph.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        KicksterButton(
          label: cancelLabel,
          variant: KicksterButtonVariant.text,
          onPressed: () {
            onCancel?.call();
            Navigator.of(context).pop(false);
          },
        ),
        _buildConfirmButton(context),
      ],
    );
  }

  /// Confirmar: `KicksterButton` primário; em modo [danger], `FilledButton`
  /// com o token `danger` (mesmo shape/altura do tema).
  Widget _buildConfirmButton(BuildContext context) {
    void onPressed() {
      onConfirm?.call();
      Navigator.of(context).pop(true);
    }

    if (danger) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
        child: Text(confirmLabel),
      );
    }
    return KicksterButton(label: confirmLabel, onPressed: onPressed);
  }
}

/// Helper de uso direto: abre um [KicksterDialog] e resolve com `true`/`false`
/// conforme o botão pressionado (`null` se dispensado pelo toque fora).
Future<bool?> showKicksterConfirm({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool danger = false,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => KicksterDialog(
      title: title,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}