import 'package:flutter/widgets.dart';

/// Constantes e wrappers de layout do Flag Platform.
///
/// Delimita a largura dos componentes em telas largas (padrão web) para
/// preservar legibilidade e hierarquia, conforme `docs/design/tokens.md`.
/// Referências de mercado: formulários ~600px, leitura/detalhe ~720px,
/// listagens/conteúdo ~1200px.
class AppLayout {
  /// Largura máxima de formulários (wizard e CRUD).
  static const double maxFormWidth = 600;

  /// Largura máxima de telas de detalhe/leitura.
  static const double maxDetailWidth = 720;

  /// Largura máxima de listagens e conteúdo.
  static const double maxContentWidth = 1200;

  /// Centraliza um formulário (coluna única) com largura máxima.
  static Widget form({required Widget child}) =>
      _wrap(maxFormWidth, child);

  /// Centraliza uma tela de detalhe/leitura com largura máxima.
  static Widget detail({required Widget child}) =>
      _wrap(maxDetailWidth, child);

  /// Centraliza uma listagem/conteúdo com largura máxima.
  static Widget content({required Widget child}) =>
      _wrap(maxContentWidth, child);

  static Widget _wrap(double maxWidth, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  const AppLayout._();
}
