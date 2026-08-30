import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Enum dos estados (tom) de um card de sessão na navegação.
enum AppSessionTone { current, done, inactive }

/// Navegação por sessões em cards centralizados (padrão #323).
///
/// Usada tanto no wizard (cadastro/edição) quanto na tela de detalhe, com os
/// MESMOS cards: um `Card` + `InkWell` (interação idêntica aos cards de lista,
/// #300) com estados por preenchimento e conteúdo BRANCO sobre `primary`
/// (sessão atual/selecionada) e sobre `success` (sessão concluída, #294).
///
/// Cada card exibe um **ícone representativo da sessão + rótulo** (issue #326):
/// o ícone substitui o `check` no estado concluído — a cor comunica o estado.
///
/// - **Atual/selecionada** = fundo `primary` + ícone e texto BRANCOS (negrito)
/// - **Concluída** (wizard) = fundo `success` + ícone e texto BRANCOS
/// - **Inativa/pendente** = card `surface` padrão (borda/elevação) +
///   ícone e texto `textPrimary`
///
/// Cards centralizados (`WrapAlignment.center`) e SEM numeração — o estado é
/// comunicado por cor/ícone (e pelo rótulo "Etapa X de Y", quando houver).
/// Alvo de toque ≥48px; sem hover/splash customizados.
class AppSessionNav extends StatelessWidget {
  const AppSessionNav({
    super.key,
    required this.sessions,
    required this.icons,
    required this.activeIndex,
    required this.onTap,
    this.showDoneState = false,
  });

  /// Rótulos das sessões, na ordem das seções na tela.
  final List<String> sessions;

  /// Ícones representativos de cada sessão (paralelo a [sessions], mesmo
  /// comprimento), exibidos em todos os estados — inclusive no concluído.
  final List<IconData> icons;

  /// Índice da sessão ativa/selecionada (card `primary`).
  final int activeIndex;

  /// Chamado ao tocar em um card (rola até a sessão / navega no wizard).
  final void Function(int index) onTap;

  /// Marca como concluídas (verde) as sessões anteriores à ativa.
  /// Use `true` no wizard; `false` na tela de detalhe (apenas atual/inativa).
  final bool showDoneState;

  AppSessionTone _toneFor(int index) {
    if (index == activeIndex) return AppSessionTone.current;
    if (showDoneState && index < activeIndex) return AppSessionTone.done;
    return AppSessionTone.inactive;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      icons.length == sessions.length,
      'AppSessionNav: "icons" (${icons.length}) e "sessions" '
      '(${sessions.length}) devem ter o mesmo tamanho.',
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < sessions.length; i++) _card(i),
      ],
    );
  }

  Widget _card(int index) {
    final tone = _toneFor(index);
    final filled = tone != AppSessionTone.inactive;
    final background = switch (tone) {
      AppSessionTone.current => AppColors.primary,
      AppSessionTone.done => AppColors.success,
      AppSessionTone.inactive => null,
    };
    final contentColor = filled ? Colors.white : AppColors.textPrimary;

    return Semantics(
      selected: tone == AppSessionTone.current,
      button: true,
      label: sessions[index],
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(index),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[index], size: 18, color: contentColor),
                const SizedBox(width: 6),
                Text(
                  sessions[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: tone == AppSessionTone.current
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
