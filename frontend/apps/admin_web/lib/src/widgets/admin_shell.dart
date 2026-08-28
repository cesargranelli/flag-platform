import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import 'admin_breadcrumbs.dart';

/// Item do menu global do Admin Web (header/drawer).
///
/// [branchIndex] precisa espelhar a ordem das branches do
/// [StatefulShellRoute.indexedStack] no `app_router.dart`.
class _NavDestination {
  final String label;
  final IconData icon;
  final String path;
  final int branchIndex;
  final bool adminOnly;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.path,
    required this.branchIndex,
    this.adminOnly = false,
  });
}

/// Shell do Admin Web (issue #427): transforma o admin_web em um site.
///
/// Header global fixo (marca + menu de módulos + chip de usuário) sobre o
/// conteúdo da branch ativa ([StatefulNavigationShell]), com breadcrumb
/// derivado da URL. Responsivo: em telas largas (`>=960px`) o menu fica
/// horizontal no header; em telas estreitas ele colapsa em um [Drawer].
/// O estado de cada módulo é preservado pelo IndexedStack do GoRouter.
class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.navigationShell,
    required this.location,
    required this.extra,
  });

  final StatefulNavigationShell navigationShell;

  /// Caminho completo da rota atual (ex.: `/competitions/123/edit`).
  final String location;

  /// `extra` da navegação atual (usado pelo breadcrumb p/ nomear entidades).
  final Object? extra;

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Início',
      icon: Icons.home_outlined,
      path: '/',
      branchIndex: 0,
    ),
    _NavDestination(
      label: 'Organizações',
      icon: Icons.business_outlined,
      path: '/organizations',
      branchIndex: 1,
    ),
    _NavDestination(
      label: 'Campeonatos',
      icon: Icons.emoji_events_outlined,
      path: '/competitions',
      branchIndex: 2,
    ),
    _NavDestination(
      label: 'Campos',
      icon: Icons.sports_soccer,
      path: '/venues',
      branchIndex: 3,
    ),
    _NavDestination(
      label: 'Times',
      icon: Icons.groups_outlined,
      path: '/teams',
      branchIndex: 4,
    ),
    _NavDestination(
      label: 'Atletas',
      icon: Icons.person_outline,
      path: '/athletes',
      branchIndex: 5,
    ),
    _NavDestination(
      label: 'Elencos',
      icon: Icons.badge_outlined,
      path: '/rosters',
      branchIndex: 6,
    ),
    _NavDestination(
      label: 'Aprovações',
      icon: Icons.fact_check_outlined,
      path: '/approvals',
      branchIndex: 7,
      adminOnly: true,
    ),
    _NavDestination(
      label: 'Usuários',
      icon: Icons.admin_panel_settings,
      path: '/users',
      branchIndex: 8,
      adminOnly: true,
    ),
    _NavDestination(
      label: 'Teste visual',
      icon: Icons.palette_outlined,
      path: '/visual-test',
      branchIndex: 9,
      adminOnly: true,
    ),
  ];

  List<_NavDestination> _visible(bool isAdmin) =>
      [for (final d in _destinations) if (!d.adminOnly || isAdmin) d];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authControllerProvider).state.user?.role == 'ADMIN';
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final visible = _visible(isAdmin);
    final active = _activeDestination(location, visible);

    return Scaffold(
      drawer: wide
          ? null
          : _AdminDrawer(
              destinations: visible,
              activeIndex: active?.branchIndex,
              onSelected: (index) {
                Navigator.pop(context);
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
      body: Column(
        children: [
          if (wide)
            _WideHeader(
              destinations: visible,
              activeIndex: active?.branchIndex,
              onSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              onLogout: () => _confirmLogout(context, ref),
            )
          else
            _NarrowHeader(
              onLogout: () => _confirmLogout(context, ref),
            ),
          AdminBreadcrumbs(location: location, extra: extra),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  _NavDestination? _activeDestination(
    String location,
    List<_NavDestination> destinations,
  ) {
    for (final d in destinations) {
      if (d.path == '/') {
        if (location == '/') return d;
        continue;
      }
      if (location == d.path || location.startsWith('${d.path}/')) return d;
    }
    return null;
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final logout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (logout == true) {
      // O GoRouter observa o AuthController e redireciona para /login.
      ref.read(authControllerProvider.notifier).logout();
    }
  }
}

/// Header largo (`>=960px`): marca + menu horizontal + chip de usuário.
class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.destinations,
    required this.activeIndex,
    required this.onSelected,
    required this.onLogout,
  });

  final List<_NavDestination> destinations;
  final int? activeIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _Brand(onTap: () => context.go('/')),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    for (final d in destinations)
                      _HeaderNavItem(
                        label: d.label,
                        icon: d.icon,
                        selected: d.branchIndex == activeIndex,
                        onTap: () => onSelected(d.branchIndex),
                      ),
                  ],
                ),
              ),
            ),
            AdminUserChip(onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

/// Header estreito (`<960px`): hambúrguer (drawer) + marca + chip de usuário.
class _NarrowHeader extends StatelessWidget {
  const _NarrowHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Abrir menu',
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            _Brand(onTap: () => context.go('/')),
            const Spacer(),
            AdminUserChip(onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

/// Marca: escudo + nome do produto; toque volta ao início.
class _Brand extends StatelessWidget {
  const _Brand({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Admin Web',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item do menu horizontal do header; ativo com pill branco translúcido.
class _HeaderNavItem extends StatelessWidget {
  const _HeaderNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawer com os itens de menu (telas estreitas).
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.destinations,
    required this.activeIndex,
    required this.onSelected,
  });

  final List<_NavDestination> destinations;
  final int? activeIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppColors.primary, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Admin Web',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final d in destinations)
              ListTile(
                leading: Icon(
                  d.icon,
                  color: d.branchIndex == activeIndex
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                title: Text(
                  d.label,
                  style: TextStyle(
                    fontWeight: d.branchIndex == activeIndex
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: d.branchIndex == activeIndex
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                selected: d.branchIndex == activeIndex,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                onTap: () => onSelected(d.branchIndex),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip de usuário da navbar global (issue #284, movido para o shell na #427).
///
/// Composição: avatar circular de 32px (fundo `surface`, iniciais em
/// `primary` — ou ícone persona quando o nome está vazio/null) + nome em
/// branco, 13px w600, com ellipsis. O chip tem um scrim escuro sutil
/// (preto @25%): sobre o header `primary` (#FD6B22), nenhum tom claro atinge
/// AA 4.5:1 — o scrim eleva o contraste do texto branco para ~4.8:1 e ainda
/// delimita visualmente o alvo de toque (raio `radius.chip` = 10).
class AdminUserChip extends ConsumerWidget {
  const AdminUserChip({super.key, required this.onLogout});

  final VoidCallback onLogout;

  /// Alvo de toque mínimo do design system (tokens.md).
  static const double _tapTargetHeight = 48;

  static final RegExp _wordSeparator = RegExp(r'[\s-]+');

  String _displayName(String? name) => (name ?? '').trim();

  /// Primeiras letras dos dois primeiros nomes ("Maria Silva" -> "MS").
  String _initials(String? name) {
    final parts = _displayName(name)
        .split(_wordSeparator)
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).state.user?.name;
    final displayName = _displayName(name);
    final hasName = displayName.isNotEmpty;
    // Responsivo: abaixo de 480px de viewport o nome colapsa e resta o
    // avatar (com menu).
    final showName = hasName && MediaQuery.sizeOf(context).width >= 480;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<String>(
        tooltip: 'Opções da conta',
        onSelected: (value) {
          if (value == 'logout') onLogout();
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_outlined, size: 20),
                SizedBox(width: 8),
                Text('Sair'),
              ],
            ),
          ),
        ],
        // SizedBox de 48px garante o alvo de toque na altura do chip.
        child: SizedBox(
          height: _tapTargetHeight,
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surface,
                    child: hasName
                        ? Text(
                            _initials(name),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                  ),
                  if (showName) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}