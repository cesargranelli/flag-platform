import 'dart:math' as math;

import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Destino configurável da navegação principal do Public App.
///
/// Data-driven: para encaixar uma futura aba "Ao vivo" basta adicionar um
/// item aqui (e a branch correspondente no roteador). A rota de destino é
/// resolvida no toque — a aba Campeonato navega para o campeonato em foco ou
/// para o orientador quando vazio.
class _NavDestination {
  final String label;
  final IconData icon;

  const _NavDestination({required this.label, required this.icon});
}

/// Shell do Public App: envolve o conteúdo das abas com a navegação principal.
///
/// Em telas largas (`>=960px`) exibe um [NavigationRail]; em telas estreitas,
/// a barra flutuante arredondada (estilo Shifty/Flag). O estado de cada aba é
/// preservado pelo [StatefulNavigationShell] do GoRouter (IndexedStack).
class PublicShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const PublicShell({super.key, required this.navigationShell});

  static const List<_NavDestination> _destinations = [
    _NavDestination(label: 'Início', icon: Icons.home_rounded),
    _NavDestination(label: 'Campeonato', icon: Icons.emoji_events_rounded),
    _NavDestination(label: 'Ao vivo', icon: Icons.sensors_rounded),
    _NavDestination(label: 'Sobre', icon: Icons.info_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return wide
            ? _RailShell(navigationShell: navigationShell)
            : _BottomShell(navigationShell: navigationShell);
      },
    );
  }
}

/// Resolve a rota de uma aba ao ser tocada.
///
/// A aba Campeonato não tem rota fixa: navega para o campeonato em foco
/// (`/competition/{id}`) ou, sem foco, para `/competition` (orientador).
void _goToTab(BuildContext context, WidgetRef ref, int index) {
  if (index == 1) {
    final focus = ref.read(focusedCompetitionProvider);
    context.go(focus != null ? '/competition/${focus.id}' : '/competition');
    return;
  }
  context.go(switch (index) {
    0 => '/',
    2 => '/live',
    3 => '/about',
    _ => '/',
  });
}

/// Shell estreito (`<960px`): barra inferior flutuante.
class _BottomShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _BottomShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FlagBottomBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _goToTab(context, ref, index),
      ),
    );
  }
}

/// Shell largo (`>=960px`): NavigationRail à esquerda com o conteúdo à direita.
class _RailShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _RailShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            color: AppColors.surface,
            child: NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _goToTab(context, ref, index),
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.8,
              indicatorColor: AppColors.primary.withValues(alpha: 0.12),
              selectedIconTheme: const IconThemeData(
                color: AppColors.primary,
                size: 28,
              ),
              unselectedIconTheme: const IconThemeData(
                color: AppColors.textSecondary,
                size: 24,
              ),
              selectedLabelTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              unselectedLabelTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              destinations: [
                for (final destination in PublicShell._destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    label: Text(destination.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// Barra inferior flutuante (estilo Shifty): fundo `surface`, raio 32,
/// margem lateral 16, sombra para cima (`0x17201F1F` blur 56 offset (0,−7)),
/// respeitando a safe area inferior.
class _FlagBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _FlagBottomBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x17201F1F),
              blurRadius: 56,
              offset: Offset(0, -7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              for (var i = 0; i < PublicShell._destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    label: PublicShell._destinations[i].label,
                    icon: PublicShell._destinations[i].icon,
                    selected: i == currentIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item da navegação: círculo/ícone + rótulo + indicador quando ativo.
///
/// O item inteiro é o alvo de toque (`>=48px`). O ícone é decorativo
/// (`excludeSemantics`) — o rótulo é exposto via [Semantics].
class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 69,
                child: Center(
                  child: selected
                      ? _ActiveCircle(icon: icon)
                      : ExcludeSemantics(
                          child: Icon(
                            icon,
                            size: 30,
                            color: AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: selected
                    ? const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )
                    : const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
              ),
              // Barrinha sob o item ativo (134x5), limitada à largura do item
              // para não estourar em telas muito estreitas.
              if (selected) ...[
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) => Container(
                    width: math.min(134.0, constraints.maxWidth),
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0x26040415),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo branco 69px com sombra atrás do ícone primário (item ativo).
class _ActiveCircle extends StatelessWidget {
  final IconData icon;

  const _ActiveCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 69,
      height: 69,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F201F1F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExcludeSemantics(
        child: Icon(icon, size: 30, color: AppColors.primary),
      ),
    );
  }
}
