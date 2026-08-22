import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Nota informativa exibida quando as ações de edição ficam ocultas
/// porque o usuário logado não é o criador do campeonato nem ADMIN.
///
/// Segue o padrão visual da issue #251: texto discreto em
/// [AppColors.textSecondary] com fontSize 13, sem contorno nem botão.
class EditRestrictionNote extends StatelessWidget {
  const EditRestrictionNote({
    super.key,
    this.message = 'Apenas o criador do campeonato pode fazer alterações.',
    this.padding = const EdgeInsets.only(top: 8),
  });

  /// Mensagem contextual exibida ao usuário (pt-BR inline, padrão do app).
  final String message;

  /// Espaçamento externo: cada tela posiciona a nota em um layout distinto.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
