import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela inicial do Admin Web: menu de gestão do organizador.
///
/// Em telas largas (>= 960px) exibe um NavigationRail lateral (padrão
/// desktop); em telas estreitas, o menu em lista vertical (padrão mobile).
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;
    final isAdmin = auth.state.user?.role == 'ADMIN';

    final items = <_MenuItem>[
      _MenuItem(Icons.business, 'Organizações', '/organizations'),
      _MenuItem(Icons.emoji_events_outlined, 'Campeonatos', '/competitions'),
      _MenuItem(Icons.category_outlined, 'Categorias', '/categories'),
      _MenuItem(Icons.sports_soccer, 'Campos', '/venues'),
      _MenuItem(Icons.groups_outlined, 'Times', '/teams'),
      _MenuItem(Icons.format_list_numbered, 'Rodadas', '/rounds'),
      _MenuItem(Icons.sports, 'Jogos', '/games'),
      _MenuItem(Icons.person_outline, 'Atletas', '/athletes'),
      _MenuItem(Icons.groups_outlined, 'Elenco', '/rosters'),
      if (isAdmin) _MenuItem(Icons.admin_panel_settings, 'Usuários', '/users'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Web'),
            actions: [
              if (wide)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(child: Text(userName ?? 'organizador')),
                ),
              IconButton(
                tooltip: 'Sair',
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: 0,
                      onDestinationSelected: (index) =>
                          context.push(items[index].route),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final item in items)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.title),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard,
                                size: 64, color: AppColors.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Bem-vindo, ${userName ?? 'organizador'}!',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Selecione uma opção no menu lateral para gerenciar os cadastros.',
                              style: TextStyle(
                                  fontSize: 16, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Bem-vindo, ${userName ?? 'organizador'}!',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (final item in items)
                      _menuItem(
                        context,
                        icon: item.icon,
                        title: item.title,
                        onTap: () => context.push(item.route),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
