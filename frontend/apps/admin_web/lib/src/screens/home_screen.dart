import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Tela inicial do Admin Web: cards de acesso às áreas de gestão.
///
/// Substitui o antigo menu lateral (NavigationRail/lista) por cards na tela,
/// mantendo os mesmos ícones e rótulos. Responsivo: grid de cards em telas
/// largas, coluna adaptada em telas estreitas.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;
    final isAdmin = auth.state.user?.role == 'ADMIN';

final items = <_MenuItem>[
      _MenuItem(Icons.business, 'Organizações', '/organizations'),
      _MenuItem(Icons.emoji_events_outlined, AppStrings.competitions, '/competitions'),
      _MenuItem(Icons.sports_soccer, AppStrings.venues, '/venues'),
      // Rodadas e jogos removidos da home (#309/#347): acesso via contexto do
      // campeonato (rodadas → confrontos).
      _MenuItem(Icons.person_outline, AppStrings.athletes, '/athletes'),
      _MenuItem(Icons.groups_outlined, AppStrings.rosters, '/rosters'),
      if (isAdmin) _MenuItem(Icons.fact_check_outlined, 'Aprovações', '/approvals'),
      if (isAdmin) _MenuItem(Icons.admin_panel_settings, AppStrings.users, '/users'),
    ];

    return AppScreen(
      title: 'Início',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final columns = wide ? 4 : 2;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${AppStrings.welcome}, ${userName ?? 'organizador'}!',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: wide ? 1.4 : 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _menuCard(
                        context,
                        icon: item.icon,
                        title: item.title,
                        onTap: () => context.go(item.route),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String route;

  const _MenuItem(this.icon, this.title, this.route);
}