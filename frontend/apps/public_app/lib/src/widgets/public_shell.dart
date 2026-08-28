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
    _NavDestination(label: 'Ao vivo', icon: Icons.sensors_rounded),
    _NavDestination(label: 'Campeonato', icon: Icons.emoji_events_rounded),
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
/// Usa [StatefulNavigationShell.goBranch] para transições suaves entre abas.
/// A aba Campeonato navega para o campeonato em foco ou para `/competition`.
void _goToTab(
  BuildContext context,
  WidgetRef ref,
  StatefulNavigationShell navigationShell,
  int index,
) {
  if (index == 1) {
    final focus = ref.read(focusedCompetitionProvider);
    final path = focus != null ? '/competition/${focus.id}' : '/competition';
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    context.go(path);
    return;
  }
  navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );
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
        onDestinationSelected: (index) => _goToTab(context, ref, navigationShell, index),
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
              onDestinationSelected: (index) => _goToTab(context, ref, navigationShell, index),
              labelType: NavigationRailLabelType.none,
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

/// Barra inferior flutuante (fiel ao Figma Shifty): fundo PRETO `#1B1D21`,
/// raio 20, margem lateral 16, sombra para cima (`0x17201F1F` blur 56 offset
/// (0,−7)), respeitando a safe area inferior. `clipBehavior: Clip.none` para o
/// círculo branco do item ativo "flutuar" acima da barra.
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
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: const Color(0xFF1B1D21),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x17201F1F),
              blurRadius: 56,
              offset: Offset(0, -7),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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

/// Item da navegação: ícone + rótulo; quando ativo, o ícone fica dentro de um
/// **círculo branco 69px** (que flutua sobre a barra) `AppColors.primary` e
/// há uma **barrinha `#333333`** abaixo.
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
                height: 60,
                child: Center(
                  child: selected
                      ? _ActiveBadge(icon: icon)
                      : ExcludeSemantics(
                          child: Icon(icon, size: 24, color: Colors.white),
                        ),
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (context, constraints) => Container(
                    width: math.min(100.0, constraints.maxWidth),
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
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

/// Item ativo: círculo branco 52px (Ellipse 6) sobre um **halo cinza `#C4C4C4`
/// de 64px** (Ellipse 5), centrados no mesmo ponto, "flutuando" ~8px acima da
/// barra (estilo Shifty), com o ícone primário dentro.
class _ActiveBadge extends StatelessWidget {
  final IconData icon;

  const _ActiveBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Halo cinza 64x64 (Ellipse 5) atrás do círculo branco.
          const SizedBox(
            width: 64,
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFC4C4C4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Círculo branco 52x52 (Ellipse 6) com o ícone primário.
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33202020),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ExcludeSemantics(
              child: Icon(icon, size: 24, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
