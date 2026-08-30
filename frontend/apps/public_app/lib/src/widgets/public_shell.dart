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
        onDestinationSelected: (index) =>
            _goToTab(context, ref, navigationShell, index),
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
              onDestinationSelected: (index) =>
                  _goToTab(context, ref, navigationShell, index),
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

/// Barra inferior Material: colada no bottom, ocupando toda a largura.
///
/// Seguindo o padrão Material Design 3 NavigationBar, com indicador animado
/// e rótulos visíveis para acessibilidade.
class _FlagBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _FlagBottomBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  State<_FlagBottomBar> createState() => _FlagBottomBarState();
}

class _FlagBottomBarState extends State<_FlagBottomBar> {
  double? _previousIndicatorCenter;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 250);
    final destinationCount = PublicShell._destinations.length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinationCount;
              final indicatorCenter =
                  itemWidth * widget.currentIndex + itemWidth / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Tab items row.
                  Row(
                    children: [
                      for (var i = 0; i < destinationCount; i++)
                        Expanded(
                          child: _NavItem(
                            label: PublicShell._destinations[i].label,
                            icon: PublicShell._destinations[i].icon,
                            selected: i == widget.currentIndex,
                            onTap: () => widget.onDestinationSelected(i),
                          ),
                        ),
                    ],
                  ),

                  // Animated indicator pill (rec. 3 + 4).
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _previousIndicatorCenter ?? indicatorCenter,
                      end: indicatorCenter,
                    ),
                    duration: animDuration,
                    curve: Curves.easeInOut,
                    onEnd: () => _previousIndicatorCenter = indicatorCenter,
                    builder: (context, value, child) {
                      return Positioned(
                        left: value - 12,
                        bottom: 0,
                        child: child!,
                      );
                    },
                    child: Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Item da navegação: ícone + rótulo; quando ativo, o ícone fica dentro de um
/// **pill indicador** na parte inferior, com o ícone na cor primária.
/// Rótulos são sempre visíveis para melhorar a acessibilidade (rec. 1).
/// Ícones inativos usam `AppColors.grayLabel` para criar hierarquia
/// visual (rec. 2).
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48), // rec. 5
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? AppColors.primary
                      : AppColors.grayLabel, // rec. 2
                ),
                const SizedBox(height: 4),
                Text(
                  label, // rec. 1 — always visible
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppColors.primary
                        : AppColors.grayLabel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


