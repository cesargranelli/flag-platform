import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Item da trilha de navegação do [AppScreen].
class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.route});

  final String label;

  /// Rota da listagem do módulo. Quando nula, o item é texto estático.
  final String? route;
}

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// - **Header pessoal**: avatar + nome + greeting + bell icon (sticky)
/// - **Breadcrumb** (quando houver): abaixo do header pessoal
/// - **Page Body** (scrollável, padding 24px): conteúdo da tela
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.breadcrumb,
    this.showUserHeader = true,
  });

  final String title;
  final Widget body;
  final List<BreadcrumbItem>? breadcrumb;
  final bool showUserHeader;

  @override
  Widget build(BuildContext context) {
    final crumbs = breadcrumb ?? const <BreadcrumbItem>[];
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header pessoal (sticky)
        if (showUserHeader) const _UserHeader(),
        // Breadcrumb (se houver)
        if (crumbs.isNotEmpty)
          _BreadcrumbBar(crumbs: crumbs, isWide: isWide),
        // Page body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: body,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User Header
// ---------------------------------------------------------------------------

/// Header pessoal com avatar, nome, greeting e bell icon.
/// Avatar clicável abre menu "Sair" para baixo.
class _UserHeader extends ConsumerWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).state.user;
    final name = (user?.name ?? '').trim();
    final email = (user?.email ?? '').trim();
    final displayName = name.isNotEmpty ? name : email;
    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar + nome (clicável → menu sair estilo KicksterDropdown)
          _UserMenuAnchor(
            displayName: displayName,
            email: email,
            initials: initials,
            onLogout: () => _confirmLogout(context, ref),
          ),

          const Spacer(),

          // Home icon
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(
              Icons.home_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
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
      ref.read(authControllerProvider.notifier).logout();
    }
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'[\s-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb Bar
// ---------------------------------------------------------------------------

/// Barra de breadcrumb abaixo do header pessoal.
class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({required this.crumbs, required this.isWide});

  final List<BreadcrumbItem> crumbs;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      child: Row(
        children: [
          isWide
              ? _BreadcrumbTrail(crumbs: crumbs)
              : _BackCrumb(
                  label: crumbs.first.label,
                  route: crumbs.first.route,
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb components
// ---------------------------------------------------------------------------

/// Trilha de breadcrumb: `Módulo › Nome` em desktop.
class _BreadcrumbTrail extends StatelessWidget {
  const _BreadcrumbTrail({required this.crumbs});

  final List<BreadcrumbItem> crumbs;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0) _crumbSeparator(),
          _CrumbLink(label: crumbs[i].label, route: crumbs[i].route),
        ],
      ],
    );
  }

  static Widget _crumbSeparator() => const Text(
        '›',
        style: TextStyle(
          fontSize: 14,
          height: 1,
          color: AppColors.textSecondary,
        ),
      );
}

/// Navega para a listagem do módulo (breadcrumb/back).
void _goToListing(BuildContext context, String? route) {
  final target = route;
  if (target == null) return;
  context.go(target);
}

/// Link de nível do breadcrumb.
class _CrumbLink extends StatefulWidget {
  const _CrumbLink({required this.label, this.route});

  final String label;
  final String? route;

  @override
  State<_CrumbLink> createState() => _CrumbLinkState();
}

class _CrumbLinkState extends State<_CrumbLink> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.route != null;
    return Focus(
      canRequestFocus: clickable,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: MouseRegion(
        cursor: clickable ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: clickable
              ? () => _goToListing(context, widget.route)
              : null,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              widget.label,
              style: _crumbTextStyle(clickable: clickable).copyWith(
                decoration: clickable && (_hovered || _focused)
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Back button do breadcrumb em viewports < 960px.
class _BackCrumb extends StatelessWidget {
  const _BackCrumb({required this.label, this.route});

  final String label;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Voltar para $label',
        child: InkWell(
          onTap: route == null ? null : () => _goToListing(context, route),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Semantics(
              label: 'Voltar para $label',
              button: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(label, style: _crumbTextStyle(clickable: true)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estilo dos níveis do breadcrumb.
TextStyle _crumbTextStyle({required bool clickable}) {
  return TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.07,
    color: clickable ? AppColors.primary : AppColors.textSecondary,
  );
}

// ── User menu (estilo KicksterDropdown) ─────────────────────────────────────

/// Anchor do menu do usuário — avatar + nome + greeting.
/// Ao clicar, abre um overlay com o estilo do KicksterDropdown:
/// container único, raio 12, borda `line`, fundo `surface`,
/// itens de 48px com divisores internos.
class _UserMenuAnchor extends StatefulWidget {
  const _UserMenuAnchor({
    required this.displayName,
    required this.email,
    required this.initials,
    required this.onLogout,
  });

  final String displayName;
  final String email;
  final String initials;
  final VoidCallback onLogout;

  @override
  State<_UserMenuAnchor> createState() => _UserMenuAnchorState();
}

class _UserMenuAnchorState extends State<_UserMenuAnchor> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _menuOpen = false;

  void _toggleMenu() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return;
    final renderBox = anchorContext.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _UserMenuOverlay(
        anchorOffset: offset,
        anchorWidth: size.width,
        anchorBottom: offset.dy + size.height,
        displayName: widget.displayName,
        email: widget.email,
        initials: widget.initials,
        onSelect: (action) {
          _closeMenu();
          if (action == 'logout') {
            widget.onLogout();
          }
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _menuOpen = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = widget.displayName.isNotEmpty
        ? 'Olá, bem-vindo!'
        : 'Bem-vindo!';

    return GestureDetector(
      key: _anchorKey,
      onTap: _toggleMenu,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: widget.initials.isNotEmpty
                ? Text(
                    widget.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Overlay do menu do usuário — segue o padrão KicksterDropdown:
/// container único, raio 12, fundo `surface`, borda `line`,
/// itens de 48px com divisores internos.
class _UserMenuOverlay extends StatelessWidget {
  const _UserMenuOverlay({
    required this.anchorOffset,
    required this.anchorWidth,
    required this.anchorBottom,
    required this.displayName,
    required this.email,
    required this.initials,
    required this.onSelect,
  });

  final Offset anchorOffset;
  final double anchorWidth;
  final double anchorBottom;
  final String displayName;
  final String email;
  final String initials;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => onSelect('dismiss'),
            ),
          ),
          // Menu container
          Positioned(
            left: anchorOffset.dx,
            top: anchorBottom + 8,
            width: anchorWidth.clamp(200, 300),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User info row (48px)
                    _UserMenuItem(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            child: initials.isNotEmpty
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.line),
                    // Logout row (48px)
                    _UserMenuItem(
                      onTap: () => onSelect('logout'),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.logout_outlined,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sair',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item do menu do usuário — 48px, padding horizontal 16px,
/// segue o padrão KicksterDropdown.
class _UserMenuItem extends StatelessWidget {
  const _UserMenuItem({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
