import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Shell do Admin Web (issue #427), simplificado na issue #433.
///
/// Header global fixo (menu de módulos + chip de usuário) sobre o conteúdo
/// da branch ativa ([StatefulNavigationShell]). O menu horizontal (issue
/// #449) devolve o contexto de navegação entre módulos ao header, sem
/// dropdown nem hambúrguer. O estado de cada módulo é preservado pelo
/// IndexedStack do GoRouter.
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

/// Header global: menu de módulos (>=960px) + chip de usuário.
///
/// O menu horizontal (issue #449) devolve o contexto de navegação entre
/// módulos ao header, sem dropdown nem hambúrguer: itens discretos em branco
/// translúcido sobre o fundo `primary`, com o item ativo em pill branco @14%.
/// Times/Rodadas/Jogos/Conferências ficam fora — são módulos contextuais
/// acessados a partir do detalhe do campeonato. Abaixo de 960px o menu é
/// ocultado (resta o chip de usuário), pois os cards da home já cobrem a
/// navegação.
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
  /// `requiresAdmin` oculta Aprovações/Usuários para não-ADMIN.
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

/// Dados de um item do menu de módulos (label + branch + restrição de role).
class _ModuleNavItemData {
  const _ModuleNavItemData(this.label, this.index, {this.requiresAdmin = false});

  final String label;
  final int index;
  final bool requiresAdmin;
}

/// Item discreto do menu de módulos do header (issue #449).
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
          // O splash (ripple) do tema permanece; hover/foco usam os estados
          // visuais próprios abaixo (Ink) para não duplicar overlay.
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

/// Chip de usuário da navbar global (issue #284, movido para o shell na #427).
///
/// Composição: avatar circular de 32px (fundo `surface`, iniciais em
/// `primary` — ou ícone persona quando o nome está vazio/null) + nome em
/// branco, 13px w600, com ellipsis. Sobre o header `primary` (azul royal
/// #083879, branco ~7.7:1), o fundo é branco translúcido suave (@10% —
/// refinamento #439): apenas delimita o alvo de toque (raio `radius.chip` =
/// 10) sem escurecer o azul. Ações via menu discreto (`PopupMenuButton`)
/// com "Sair" (ícone logout + texto).
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
                color: Colors.white.withValues(alpha: 0.10),
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