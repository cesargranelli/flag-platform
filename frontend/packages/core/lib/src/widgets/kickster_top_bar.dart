import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'kickster_avatar.dart';

/// Item da [KicksterTopBar].
///
/// Sem [children] é um link simples ([onTap]); com sub-itens vira um dropdown
/// (`MenuAnchor` na web / `ExpansionTile` no drawer mobile). [selected]
/// destaca o item (scrim branco @18% na web).
class KicksterTopBarItem {
  const KicksterTopBarItem({
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.children,
  });

  final String label;
  final IconData? icon;

  /// Ação do item (ignorada quando [children] é fornecido).
  final VoidCallback? onTap;

  final bool selected;

  /// Sub-itens: transforma o item em um dropdown/menu.
  final List<KicksterTopBarItem>? children;

  bool get hasChildren => children != null && children!.isNotEmpty;
}

/// Navbar web de topo no estilo do kit Kickster (issue #441).
///
/// Fundo `primary`, textos brancos, altura 64. Responsiva:
/// - **≥960px**: brand à esquerda + links horizontais (com dropdowns via
///   `MenuAnchor` em painel `surface` raio 16) + user area à direita;
/// - **<960px**: brand + hambúrguer abrindo um drawer (painel `surface`).
///
/// Uso: telas autenticadas (admin_web/public_app). **Não usar em telas
/// públicas de auth** — elas não têm navbar.
class KicksterTopBar extends StatelessWidget {
  const KicksterTopBar({
    super.key,
    required this.brandTitle,
    this.brandIcon,
    this.items = const [],
    this.userLabel,
    this.onLogout,
  });

  final String brandTitle;
  final IconData? brandIcon;
  final List<KicksterTopBarItem> items;

  /// Nome do usuário exibido na user area (com avatar de iniciais).
  final String? userLabel;

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    return Container(
      height: 64,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: isDesktop ? _buildDesktop(context) : _buildMobile(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop (≥960px)
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(BuildContext context) {
    return Row(
      children: [
        _buildBrand(foreground: Colors.white),
        const SizedBox(width: 32),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in items) ...[
                  _buildDesktopItem(context, item),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        _buildUserArea(context),
      ],
    );
  }

  Widget _buildDesktopItem(BuildContext context, KicksterTopBarItem item) {
    final trigger = _buildItemTrigger(item);

    if (!item.hasChildren) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(10),
        child: trigger,
      );
    }

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor:
            WidgetStatePropertyAll(AppColors.black.withValues(alpha: 0.15)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      menuChildren: [
        for (final child in item.children!)
          MenuItemButton(
            leadingIcon: child.icon == null
                ? null
                : Icon(child.icon, size: 18, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).pop();
              child.onTap?.call();
            },
            child: Text(child.label),
          ),
      ],
      builder: (context, controller, _) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(10),
          child: trigger,
        );
      },
    );
  }

  Widget _buildItemTrigger(KicksterTopBarItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: item.selected
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 22 / 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.07,
            ),
          ),
          if (item.hasChildren) ...[
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
          ],
        ],
      ),
    );
  }

  Widget _buildUserArea(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userLabel != null) ...[
          KicksterAvatar(name: userLabel, size: 32),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              userLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (onLogout != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Sair',
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile (<960px)
  // ---------------------------------------------------------------------------

  Widget _buildMobile(BuildContext context) {
    return Row(
      children: [
        _buildBrand(foreground: Colors.white),
        const Spacer(),
        IconButton(
          tooltip: 'Menu',
          onPressed: () => _openDrawer(context),
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
      ],
    );
  }

  /// Drawer lateral esquerdo (painel `surface`) com os itens da barra.
  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar menu',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, _) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: AppColors.surface,
          elevation: 8,
          child: SizedBox(
            width: 280,
            height: double.infinity,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildBrand(foreground: AppColors.primary),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  for (final item in items) _buildDrawerItem(context, item),
                  const Spacer(),
                  if (userLabel != null || onLogout != null) ...[
                    const Divider(height: 1, color: AppColors.line),
                    _buildDrawerUser(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildDrawerItem(BuildContext context, KicksterTopBarItem item) {
    if (item.hasChildren) {
      return ExpansionTile(
        leading:
            item.icon == null ? null : Icon(item.icon, color: AppColors.primary),
        title: Text(
          item.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          for (final child in item.children!)
            ListTile(
              dense: true,
              leading: child.icon == null
                  ? null
                  : Icon(child.icon, size: 20, color: AppColors.primary),
              title: Text(
                child.label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.of(context).pop();
                child.onTap?.call();
              },
            ),
        ],
      );
    }

    return ListTile(
      selected: item.selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      leading: item.icon == null
          ? null
          : Icon(
              item.icon,
              color:
                  item.selected ? AppColors.primary : AppColors.textSecondary,
            ),
      title: Text(
        item.label,
        style: TextStyle(
          color: item.selected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        item.onTap?.call();
      },
    );
  }

  Widget _buildDrawerUser(BuildContext context) {
    return ListTile(
      leading: KicksterAvatar(name: userLabel, size: 32),
      title: Text(
        userLabel ?? '',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: onLogout == null
          ? null
          : IconButton(
              tooltip: 'Sair',
              onPressed: () {
                Navigator.of(context).pop();
                onLogout?.call();
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
            ),
    );
  }

  Widget _buildBrand({required Color foreground}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (brandIcon != null) ...[
          Icon(brandIcon, color: foreground, size: 24),
          const SizedBox(width: 8),
        ],
        Text(
          brandTitle,
          style: TextStyle(
            color: foreground,
            fontSize: 18,
            height: 26 / 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.09,
          ),
        ),
      ],
    );
  }
}