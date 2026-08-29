import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Tela inicial do Admin Web (issue #433): grade de cards no estilo Kickster.
///
/// Com o [AppScreen] (issue #455) ganhou o título "Início" (semântica header)
/// e o subtítulo "Olá, {nome}!" (14px `textSecondary`) acima da grade. Cada
/// card tem ícone grande + título do módulo (`KicksterCard` do core — raio
/// 12, fundo `surface`, elevação sutil). A navegação entre módulos também é
/// feita por aqui (o header tem menu discreto acima de 960px — issue #449).
/// Grade responsiva: `>=960px` → 4 colunas; abaixo → 2 colunas.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).state;
    final isAdmin = authState.user?.role == 'ADMIN';
    final name = (authState.user?.name ?? '').trim();

    final modules = <_Module>[
      _Module(
        Icons.business_outlined,
        AppStrings.organizations,
        '/organizations',
      ),
      _Module(
        Icons.emoji_events_outlined,
        AppStrings.competitions,
        '/competitions',
      ),
      _Module(Icons.sports_soccer, AppStrings.venues, '/venues'),
      _Module(Icons.person_outline, AppStrings.athletes, '/athletes'),
      _Module(Icons.groups_outlined, AppStrings.teams, '/teams'),
      _Module(Icons.groups_2_outlined, AppStrings.rosters, '/rosters'),
      if (isAdmin)
        _Module(Icons.fact_check_outlined, 'Aprovações', '/approvals'),
      if (isAdmin)
        _Module(Icons.admin_panel_settings, AppStrings.users, '/users'),
    ];

    return AppScreen(
      title: 'Início',
      titleVariant: AppScreenTitleVariant.titleLg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: AppLayout.content(
              child: Text(
                name.isEmpty ? 'Olá!' : 'Olá, $name!',
                style: AppTextStyles.paragraph.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                return GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: wide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: wide ? 1.6 : 1.3,
                  children: [
                    for (final module in modules)
                      KicksterCard(
                        icon: module.icon,
                        title: module.title,
                        onTap: () => context.go(module.route),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final String title;
  final String route;

  const _Module(this.icon, this.title, this.route);
}