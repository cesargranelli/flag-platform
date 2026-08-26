import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de navegação por sessões (chips roláveis) da tela de detalhe (#323).
///
/// Reflete as MESMAS sessões do wizard de cadastro: chip **ativo** com fundo
/// `primary` e texto branco, chip **inativo** com fundo `grayFill` e texto
/// `textPrimary`. A rolagem até a seção fica a cargo do pai, via [onTap].
/// Alvo de toque mínimo de 48px; interação via `InkWell` padrão do tema,
/// sem hover/splash customizados (#300).
class AppSessionNavBar extends StatelessWidget {
  const AppSessionNavBar({
    super.key,
    required this.sessions,
    required this.activeIndex,
    required this.onTap,
  });

  /// Rótulos das sessões, na mesma ordem das seções na tela.
  final List<String> sessions;

  /// Índice da sessão ativa (chip destacado).
  final int activeIndex;

  /// Chamado ao tocar em um chip (rola até a sessão).
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == activeIndex;
          return Semantics(
            selected: active,
            button: true,
            child: InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.grayFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sessions[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
