import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import 'kickster_breadcrumb.dart';

/// Item da trilha de navegação do [AppScreen].
class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.route, this.icon});

  final String label;

  /// Rota da listagem do módulo. Quando nula, o item é texto estático.
  final String? route;

  /// Ícone opcional antes do texto (ex: home_outlined).
  final IconData? icon;
}

/// Scaffold padrão das telas autenticadas do Admin Web.
///
/// - **Header pessoal**: avatar + nome + greeting + home icon (sticky)
/// - **Breadcrumb** (quando houver): abaixo do header pessoal
/// - **Page Body** (scrollável, padding 24px): conteúdo da tela
class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.breadcrumb,
    this.showUserHeader = true,
    this.scrollable = true,
  });

  final String title;
  final Widget body;
  final List<BreadcrumbItem>? breadcrumb;
  final bool showUserHeader;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final crumbs = breadcrumb ?? const <BreadcrumbItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header pessoal (sticky)
        if (showUserHeader) const _UserHeader(),
        if (scrollable)
          // Page body (breadcrumb + conteúdo, scrollável)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildBody(crumbs),
            ),
          )
        else
          // Page body (breadcrumb + conteúdo) em altura finita (Expanded):
          // usado pelas telas de listagem para permitir scroll raiz LIGHT
          // (virtualização real via altura finita nos grids/lists).
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildBody(crumbs),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(List<BreadcrumbItem> crumbs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Breadcrumb inline (sem barra separada)
        if (crumbs.isNotEmpty) ...[
          KicksterBreadcrumb(
            items: [
              for (var i = 0; i < crumbs.length; i++)
                KicksterBreadcrumbItem(
                  label: crumbs[i].label,
                  route: crumbs[i].route,
                  icon: crumbs[i].icon ??
                      (i == 0 && crumbs[i].route == '/'
                          ? Icons.home_outlined
                          : null),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Quando scrollable=false, o body precisa receber altura finita via
        // Expanded para que telas com Expanded interno (grids/lists) não
        // recebam constraints ilimitadas (fix "RenderFlex children have
        // non-zero flex but incoming height constraints are unbounded").
        if (scrollable)
          body
        else
          Expanded(child: body),
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
    final user = ref.watch(authControllerProvider.select((a) => a.state.user));
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

// ── User menu (estilo KicksterDropdown) ─────────────────────────────────────

/// Anchor do menu do usuário — avatar + nome + greeting.
/// Abre um [KicksterMenuAnchor] com o estilo do KicksterDropdown:
/// container único, raio 12, borda `line`, fundo `surface`,
/// itens de 48px com divisores internos.
class _UserMenuAnchor extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final greeting = displayName.isNotEmpty ? 'Olá, bem-vindo!' : 'Bem-vindo!';

    return KicksterMenuAnchor(
      triggerLabel: 'Menu do usuário',
      trigger: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KicksterAvatar(name: displayName, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
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
      items: [
        // Cabeçalho do usuário (informativo, sem ação).
        KicksterMenuItem(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
        // Sair (48px, ícone logout danger).
        KicksterMenuItem(
          onTap: onLogout,
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
    );
  }
}
