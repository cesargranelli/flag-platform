import 'dart:async';

import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import 'admin_breadcrumbs.dart';

/// Item de um grupo do menu global do Admin Web (ex.: "Campeonatos" dentro
/// de Competições).
class _NavItem {
  final String label;
  final IconData icon;
  final String path;

  /// Insere um divisor antes deste item no dropdown (ex.: "Teste visual").
  final bool dividerBefore;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
    this.dividerBefore = false,
  });
}

/// Grupo do menu global do Admin Web (header/drawer).
///
/// Destinos de 1ª ordem: links diretos (`children` vazio) ou grupos com
/// dropdown (`children` preenchido; o 1º item é a landing do grupo).
/// [branchIndex] espelha a ordem das branches do
/// [StatefulShellRoute.indexedStack] no `app_router.dart`.
class _NavDestination {
  final String label;
  final IconData icon;
  final String path;
  final int branchIndex;
  final bool adminOnly;
  final List<_NavItem> children;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.path,
    required this.branchIndex,
    this.adminOnly = false,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
}

/// Shell do Admin Web (issue #427): transforma o admin_web em um site.
///
/// Header global fixo (marca + menu de módulos + chip de usuário) sobre o
/// conteúdo da branch ativa ([StatefulNavigationShell]), com breadcrumb
/// derivado da URL. Responsivo: em telas largas (`>=960px`) o menu fica
/// horizontal no header; em telas estreitas ele colapsa em um [Drawer].
/// O estado de cada módulo é preservado pelo IndexedStack do GoRouter.
///
/// Menu reformulado na issue #431 (identidade Kickster): grupos de 1ª ordem
/// com dropdown (Competições, Equipes, Administração) e links diretos
/// (Início, Organizações, Campos), item ativo por prefixo de rota.
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
      label: 'Competições',
      icon: Icons.emoji_events_outlined,
      path: '/competitions',
      branchIndex: 2,
      children: [
        _NavItem(
          label: 'Campeonatos',
          icon: Icons.emoji_events_outlined,
          path: '/competitions',
        ),
        _NavItem(
          label: 'Conferências e divisões',
          icon: Icons.account_tree_outlined,
          path: '/groupings',
        ),
        _NavItem(
          label: 'Rodadas',
          icon: Icons.calendar_month_outlined,
          path: '/rounds',
        ),
        _NavItem(
          label: 'Jogos',
          icon: Icons.sports_score_outlined,
          path: '/games',
        ),
      ],
    ),
    _NavDestination(
      label: 'Campos',
      icon: Icons.sports_soccer,
      path: '/venues',
      branchIndex: 3,
    ),
    _NavDestination(
      label: 'Equipes',
      icon: Icons.groups_outlined,
      path: '/teams',
      branchIndex: 4,
      children: [
        _NavItem(
          label: 'Times',
          icon: Icons.groups_outlined,
          path: '/teams',
        ),
        _NavItem(
          label: 'Elencos',
          icon: Icons.badge_outlined,
          path: '/rosters',
        ),
        _NavItem(
          label: 'Atletas',
          icon: Icons.person_outline,
          path: '/athletes',
        ),
      ],
    ),
    _NavDestination(
      label: 'Administração',
      icon: Icons.admin_panel_settings,
      path: '/approvals',
      branchIndex: 7,
      adminOnly: true,
      children: [
        _NavItem(
          label: 'Aprovações',
          icon: Icons.fact_check_outlined,
          path: '/approvals',
        ),
        _NavItem(
          label: 'Usuários',
          icon: Icons.admin_panel_settings,
          path: '/users',
        ),
        _NavItem(
          label: 'Teste visual',
          icon: Icons.palette_outlined,
          path: '/visual-test',
          dividerBefore: true,
        ),
      ],
    ),
  ];

  List<_NavDestination> _visible(bool isAdmin) =>
      [for (final d in _destinations) if (!d.adminOnly || isAdmin) d];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authControllerProvider).state.user?.role == 'ADMIN';
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final visible = _visible(isAdmin);
    final active = _active(location, visible);
    final activeDestination = active?.$1;
    final activePath = active?.$2;

    return Scaffold(
      drawer: wide
          ? null
          : _AdminDrawer(
              destinations: visible,
              activePath: activePath,
              onNavigate: (path) {
                Navigator.pop(context);
                context.go(path);
              },
            ),
      body: Column(
        children: [
          if (wide)
            _WideHeader(
              destinations: visible,
              activeDestination: activeDestination,
              activePath: activePath,
              onNavigate: (path) => context.go(path),
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

  /// Resolve o grupo ativo por prefixo de rota (item ativo por grupo):
  /// `/games`, `/rounds`, `/groupings` → Competições; `/athletes`, `/rosters`
  /// → Equipes; `/approvals`, `/users`, `/visual-test` → Administração;
  /// `/venues` → Campos; `/organizations` → Organizações; `/` → Início.
  ///
  /// Retorna o destino (grupo) e o caminho exato ativo dentro dele.
  (_NavDestination, String)? _active(
    String location,
    List<_NavDestination> destinations,
  ) {
    for (final d in destinations) {
      final candidates = <String>[
        d.path,
        for (final c in d.children) c.path,
      ];
      for (final path in candidates) {
        final matches = path == '/'
            ? location == '/'
            : location == path || location.startsWith('$path/');
        if (matches) return (d, path);
      }
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
///
/// Sem rolagem horizontal (issue #431): quando o menu não cabe, o [FittedBox]
/// reduz a escala proporcionalmente em vez de rolar.
class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.destinations,
    required this.activeDestination,
    required this.activePath,
    required this.onNavigate,
    required this.onLogout,
  });

  final List<_NavDestination> destinations;
  final _NavDestination? activeDestination;
  final String? activePath;
  final ValueChanged<String> onNavigate;
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final d in destinations)
                      if (d.hasChildren)
                        _HeaderDropdown(
                          destination: d,
                          selected: d == activeDestination,
                          activePath: activePath,
                          onNavigate: onNavigate,
                        )
                      else
                        _HeaderNavItem(
                          label: d.label,
                          icon: d.icon,
                          selected: d == activeDestination,
                          onTap: () => onNavigate(d.path),
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
        height: 64,
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

/// Dropdown de grupo do header (issue #431).
///
/// Abre por clique; no desktop, o hover também abre após 200ms. Fecha em
/// clique fora, Esc ou após navegação. Operável por teclado: Tab foca o
/// gatilho, Enter/Espaço abre/fecha e as setas navegam os itens do menu
/// (navegação interna do [MenuAnchor]).
class _HeaderDropdown extends StatefulWidget {
  const _HeaderDropdown({
    required this.destination,
    required this.selected,
    required this.activePath,
    required this.onNavigate,
  });

  final _NavDestination destination;
  final bool selected;
  final String? activePath;
  final ValueChanged<String> onNavigate;

  @override
  State<_HeaderDropdown> createState() => _HeaderDropdownState();
}

class _HeaderDropdownState extends State<_HeaderDropdown> {
  final MenuController _menu = MenuController();
  Timer? _hoverTimer;

  void _open() {
    _hoverTimer?.cancel();
    if (!_menu.isOpen) _menu.open();
  }

  void _scheduleOpen() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 200), _open);
  }

  void _cancelHover() => _hoverTimer?.cancel();

  @override
  void didUpdateWidget(covariant _HeaderDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Navegação externa (ex.: breadcrumb) também fecha o dropdown.
    if (oldWidget.activePath != widget.activePath) _menu.close();
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _scheduleOpen(),
      onExit: (_) => _cancelHover(),
      child: MenuAnchor(
        controller: _menu,
        alignmentOffset: const Offset(0, 8),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
          elevation: const WidgetStatePropertyAll(4),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        menuChildren: [
          for (final item in widget.destination.children) ...[
            if (item.dividerBefore)
              const Divider(
                height: 17,
                indent: 12,
                endIndent: 12,
                color: AppColors.grayFill,
              ),
            _MenuDropdownItem(
              label: item.label,
              icon: item.icon,
              selected: item.path == widget.activePath,
              onTap: () {
                _menu.close();
                widget.onNavigate(item.path);
              },
            ),
          ],
        ],
        builder: (context, controller, child) {
          return _HeaderNavItem(
            label: widget.destination.label,
            icon: widget.destination.icon,
            selected: widget.selected,
            trailing: Icons.expand_more,
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          );
        },
      ),
    );
  }
}

/// Item do menu horizontal do header; ativo com pill de scrim preto @28%
/// (texto branco w700 — contraste AA ~5.2:1 sobre o `primary` azul royal);
/// hover com scrim @15%. Itens 14px w600, ícone 16px.
class _HeaderNavItem extends StatefulWidget {
  const _HeaderNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Ícone à direita (ex.: chevron `expand_more` em grupos).
  final IconData? trailing;

  @override
  State<_HeaderNavItem> createState() => _HeaderNavItemState();
}

class _HeaderNavItemState extends State<_HeaderNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scrim = widget.selected ? 0.28 : (_hovered ? 0.15 : 0.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        selected: widget.selected,
        button: true,
        label: widget.label,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: scrim),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 4),
                  Icon(widget.trailing, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item do dropdown de grupo: altura 48px; ativo com fundo `primary` @8% +
/// texto/ícone `primary` w700.
class _MenuDropdownItem extends StatelessWidget {
  const _MenuDropdownItem({
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
    final contentColor =
        selected ? AppColors.primary : AppColors.textPrimary;
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        backgroundColor: WidgetStatePropertyAll(
          selected ? AppColors.primary.withValues(alpha: 0.08) : null,
        ),
        foregroundColor: WidgetStatePropertyAll(contentColor),
        iconColor: WidgetStatePropertyAll(contentColor),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      leadingIcon: Icon(icon, size: 16),
      child: Text(label),
    );
  }
}

/// Drawer com as seções do menu (telas estreitas).
///
/// Grupos viram seções com rótulo overline (12px uppercase `grayLabel`) e os
/// itens viram [ListTile]; links diretos (Início, Organizações, Campos)
/// aparecem como itens simples. A seção Administração só aparece para ADMIN.
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.destinations,
    required this.activePath,
    required this.onNavigate,
  });

  final List<_NavDestination> destinations;
  final String? activePath;
  final ValueChanged<String> onNavigate;

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
            for (final d in destinations) ...[
              if (d.hasChildren) ...[
                _DrawerSectionLabel(d.label),
                for (final item in d.children)
                  _DrawerItem(
                    label: item.label,
                    icon: item.icon,
                    selected: item.path == activePath,
                    onTap: () => onNavigate(item.path),
                  ),
              ] else
                _DrawerItem(
                  label: d.label,
                  icon: d.icon,
                  selected: d.path == activePath,
                  onTap: () => onNavigate(d.path),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rótulo overline de seção do drawer (12px uppercase, `grayLabel`).
class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.overlineLabel,
      ),
    );
  }
}

/// Item de navegação do drawer.
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
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
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}

/// Chip de usuário da navbar global (issue #284, movido para o shell na #427).
///
/// Composição: avatar circular de 32px (fundo `surface`, iniciais em
/// `primary` — ou ícone persona quando o nome está vazio/null) + nome em
/// branco, 13px w600, com ellipsis. O chip tem um scrim escuro sutil
/// (preto @25%): sobre o header `primary` (azul royal #083879, branco
/// ~7.7:1), o scrim reforça ainda mais o contraste do texto branco e delimita
/// visualmente o alvo de toque (raio `radius.chip` = 10).
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