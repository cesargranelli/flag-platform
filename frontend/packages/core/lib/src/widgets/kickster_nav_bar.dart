import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra de navegação **inferior mobile** no estilo do kit Kickster (issues
/// #436/#441).
///
/// Wrapper do `NavigationBar` Material 3 com os tokens da marca: fundo
/// `surface`, indicador `primary` @12% e ícone/rótulo `primary` quando
/// selecionado. Destinos são `NavigationDestination` padrão — a seleção é
/// controlada pelo chamador (ex.: índice do shell).
///
/// Para a navegação **superior web** (telas autenticadas), use a
/// [KicksterTopBar] — esta barra é o bottom nav mobile do kit.
class KicksterNavBar extends StatelessWidget {
  const KicksterNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}