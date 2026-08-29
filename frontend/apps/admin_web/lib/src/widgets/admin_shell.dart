import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Shell do Admin Web (issue #427), com sidebar esquerda no desktop (issue #457).
///
/// **Desktop (>=960px):** `Row > [Sidebar(256px), Expanded(navigationShell)]`.
/// A sidebar contém a marca, itens de navegação e chip de usuário no rodapé.
///
/// **Mobile (<960px):** `Column > [Header, Expanded(navigationShell)]`.
/// Mantém o header horizontal atual com marca + menu + chip de usuário.
class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(authControllerProvider).state.user?.role == 'ADMIN';
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              navigationShell: navigationShell,
              isAdmin: isAdmin,
              onLogout: () => _confirmLogout(context, ref),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _Header(
            onLogout: () => _confirmLogout(context, ref),
            navigationShell: navigationShell,
            isAdmin: isAdmin,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final logout = await showKicksterConfirm(
      context: context,
      title: 'Sair',
      content: 'Deseja realmente encerrar a sessão?',
      confirmLabel: 'Sair',
    );
    if (logout == true) {
      // O GoRouter observa o AuthController e redireciona para /login.
      ref.read(authControllerProvider.notifier).logout();
    }
  }
}

// ---------------------------------------------------------------------------
// Sidebar (desktop >= 1200px)
// ---------------------------------------------------------------------------

/// Sidebar esquerda fixa (256px) exibida em viewports >= 960px.
///
/// Fundo `surface` (branco), borda direita 1px `line`. Contém:
/// - Topo: marca (escudo + "Flag Platform"), clicável → home.
/// - Itens de navegação na mesma ordem do header mobile.
/// - Rodapé: chip de usuário com email + menu popup.
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.navigationShell,
    required this.isAdmin,
    required this.onLogout,
  });

  final StatefulNavigationShell navigationShell;
  final bool isAdmin;
  final VoidCallback onLogout;

  /// Itens do menu na ordem das branches do `StatefulShellRoute` (router).
  static const _items = <_ModuleNavItemData>[
    _ModuleNavItemData('Início', 0, icon: Icons.home_outlined, activeIcon: Icons.home),
    _ModuleNavItemData(AppStrings.organizations, 1, icon: Icons.apartment),
    _ModuleNavItemData(AppStrings.competitions, 2, icon: Icons.emoji_events_outlined),
    _ModuleNavItemData(AppStrings.venues, 3, icon: Icons.sports_soccer_outlined),
    _ModuleNavItemData(AppStrings.athletes, 5, icon: Icons.person_outlined),
    _ModuleNavItemData(AppStrings.rosters, 6, icon: Icons.group_outlined),
    _ModuleNavItemData('Aprovações', 7, icon: Icons.how_to_reg_outlined, requiresAdmin: true),
    _ModuleNavItemData(AppStrings.users, 8, icon: Icons.manage_accounts_outlined, requiresAdmin: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Marca
          _SidebarBrand(onTap: () => context.go('/')),

          // Itens de navegação
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  if (item.requiresAdmin && !isAdmin) {
                    return const SizedBox.shrink();
                  }
                  final active = navigationShell.currentIndex == item.index;
                  return _SidebarNavItem(
                    label: item.label,
                    icon: item.icon!,
                    activeIcon: item.activeIcon,
                    active: active,
                    onTap: () => navigationShell.goBranch(
                      item.index,
                      initialLocation: true,
                    ),
                  );
                },
              ),
            ),
          ),

          // Chip de usuário no rodapé
          _SidebarUserChip(onLogout: onLogout),
        ],
      ),
    );
  }
}

/// Marca no topo da sidebar: escudo + "Flag Platform".
///
/// Clicável, volta para a home (issue #433). Fundo `surface`, borda bottom.
class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.04),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.line, width: 1),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Flag Platform',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de navegação da sidebar.
///
/// Altura de toque 40px, padding horizontal 12, gap 10 entre ícone (20px)
/// e label (14px). Estados visuais:
/// - Ativo: fundo `primary@8%`, texto e ícone `primary` w600, raio 8.
/// - Inativo: texto `textSecondary` w500, ícone `textSecondary`.
/// - Hover: fundo `primary@4%`, texto `textPrimary`.
class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        label: widget.label,
        button: true,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.transparent,
            child: Ink(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : _hovered
                        ? AppColors.primary.withValues(alpha: 0.04)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    active ? (widget.activeIcon ?? widget.icon) : widget.icon,
                    size: 20,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active || _hovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de usuário no rodapé da sidebar (desktop >= 1200px).
///
/// fullWidth, 56px altura, padding 12, fundo `surface`, borda top 1px `line`.
/// Row: CircleAvatar 32px (fundo `primary@8%`, iniciais 13px w700 `primary`)
/// + Column [nome 13px w600 `textPrimary`, email 12px `textSecondary` com
/// ellipsis] + Spacer + ícone `keyboard_arrow_down` 18px `textSecondary`.
/// PopupMenuButton com "Minha conta" (sem ação) e "Sair" (→ onLogout).
class _SidebarUserChip extends ConsumerWidget {
  const _SidebarUserChip({required this.onLogout});

  final VoidCallback onLogout;

  static final RegExp _wordSeparator = RegExp(r'[\s-]+');

  String _displayName(String? name) => (name ?? '').trim();

  String _initials(String? name) {
    final parts = _displayName(name)
        .split(_wordSeparator)
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).state.user;
    final name = user?.name;
    final email = user?.email ?? '';
    final displayName = _displayName(name);
    final hasName = displayName.isNotEmpty;

    return Material(
      color: AppColors.surface,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        child: PopupMenuButton<String>(
          tooltip: 'Opções da conta',
          offset: const Offset(0, -8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line),
          ),
          elevation: 4,
          onSelected: (value) {
            if (value == 'logout') onLogout();
            if (value == 'account') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Em breve')),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'account',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Minha conta'),
                ],
              ),
            ),
            const PopupMenuDivider(),
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
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (mobile/tablet < 1200px)
// ---------------------------------------------------------------------------

/// Header global para mobile/tablet (< 960px): menu de módulos (>=960px) +
/// chip de usuário.
///
/// A marca `_BrandMark` fica visível (necessária sem sidebar). Abaixo de 960px
/// o menu horizontal é ocultado, restando apenas a marca e o chip.
class _Header extends StatelessWidget {
  const _Header({
    required this.onLogout,
    required this.navigationShell,
    required this.isAdmin,
  });

  final VoidCallback onLogout;
  final StatefulNavigationShell navigationShell;
  final bool isAdmin;

  /// Itens do menu na ordem das branches do `StatefulShellRoute` (router).
  static const _items = <_ModuleNavItemData>[
    _ModuleNavItemData('Início', 0),
    _ModuleNavItemData(AppStrings.organizations, 1),
    _ModuleNavItemData(AppStrings.competitions, 2),
    _ModuleNavItemData(AppStrings.venues, 3),
    _ModuleNavItemData(AppStrings.athletes, 5),
    _ModuleNavItemData(AppStrings.rosters, 6),
    _ModuleNavItemData('Aprovações', 7, requiresAdmin: true),
    _ModuleNavItemData(AppStrings.users, 8, requiresAdmin: true),
  ];

  @override
  Widget build(BuildContext context) {
    final showModules = MediaQuery.sizeOf(context).width >= 960;
    return Material(
      color: AppColors.primary,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            // Marca (necessária no mobile sem sidebar).
            _BrandMark(
              showLabel: showModules,
              onTap: () => context.go('/'),
            ),
            if (showModules)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in _items)
                            if (!item.requiresAdmin || isAdmin)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _ModuleNavItem(
                                  label: item.label,
                                  active:
                                      navigationShell.currentIndex ==
                                          item.index,
                                  onTap: () => navigationShell.goBranch(
                                    item.index,
                                    initialLocation:
                                        navigationShell.currentIndex ==
                                            item.index,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            AdminUserChip(onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

/// Mini-marca do Admin Web no header (issue #455): escudo + "Flag Platform".
///
/// Clicável, volta para a home (issue #433). O label colapsa em viewports
/// < 960px, restando apenas o escudo. O hover usa o mesmo branco translúcido
/// @8% dos itens do menu.
class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.showLabel, required this.onTap});

  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.white.withValues(alpha: 0.08),
        focusColor: Colors.white.withValues(alpha: 0.08),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 24,
                  color: Colors.white,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Flag Platform',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

/// Dados de um item do menu de módulos (label + branch + ícone + restrição).
class _ModuleNavItemData {
  const _ModuleNavItemData(
    this.label,
    this.index, {
    this.icon,
    this.activeIcon,
    this.requiresAdmin = false,
  });

  final String label;
  final int index;
  final IconData? icon;
  final IconData? activeIcon;
  final bool requiresAdmin;
}

/// Item discreto do menu de módulos do header mobile (issue #449).
///
/// Altura de toque 48px via `InkWell` padrão do tema (#300 — sem splash
/// custom, apenas os overlays de hover/foco substituídos pelos estados
/// visuais da spec). Estados: pill branco @14% (ativo, texto w700) · branco
/// @8% (hover) · outline branco 2px (foco de teclado). Raio `radius.chip`
/// (10) — mesmo valor usado no chip de usuário e nos chips do core.
class _ModuleNavItem extends StatefulWidget {
  const _ModuleNavItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_ModuleNavItem> createState() => _ModuleNavItemState();
}

class _ModuleNavItemState extends State<_ModuleNavItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Focus(
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.14)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: _focused
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: Colors.white.withValues(alpha: active ? 1 : 0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de usuário da navbar mobile (issue #284, movido para o shell na #427).
///
/// Composição: avatar circular de 32px (fundo `surface`, iniciais em
/// `primary` — ou ícone persona quando o nome está vazio/null) + nome em
/// branco, 13px w600, com ellipsis. Fundo transparente (sobre o header azul
/// `primary`). Ações via menu discreto (`PopupMenuButton`) com "Sair".
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
    );
  }
}
