import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Variantes de botão do kit Kickster (issue #436).
enum KicksterButtonVariant {
  /// Fundo `primary`, texto branco — ação principal.
  primary,

  /// Borda `primary`, texto `primary` — ação secundária.
  outline,

  /// Sem fundo/borda — ação terciária (link).
  text,
}

/// Wrapper tipado dos botões do tema (issue #436).
///
/// Conveniência sobre os temas existentes (`FilledButton`,
/// `OutlinedButton`, `TextButton`) — **nenhum estilo novo**: raio 16, altura
/// mín. 56px e cores vêm de `AppTheme`. Variantes: [KicksterButtonVariant].
/// Quando [loading] é `true`, o botão é desabilitado e exibe um spinner no
/// lugar do ícone.
class KicksterButton extends StatelessWidget {
  const KicksterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KicksterButtonVariant.primary,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KicksterButtonVariant variant;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final foreground = switch (variant) {
      KicksterButtonVariant.primary => Colors.white,
      KicksterButtonVariant.outline || KicksterButtonVariant.text =>
        AppColors.primary,
    };
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    return switch (variant) {
      KicksterButtonVariant.primary => FilledButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
      KicksterButtonVariant.outline => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
      KicksterButtonVariant.text => TextButton(
          onPressed: enabled ? onPressed : null,
          child: child,
        ),
    };
  }
}