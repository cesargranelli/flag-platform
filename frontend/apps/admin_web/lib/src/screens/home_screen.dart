import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Tela inicial do Admin Web: dashboard (issue #431).
///
/// Banda de boas-vindas (nome, data e papel) + 4 ações rápidas
/// ([FilledButton.icon] com rotas existentes) + grade de módulos mantida
/// como atalho. Tudo na paleta Kickster via [AppColors] — nada hardcoded.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  static const List<String> _months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;
    final isAdmin = auth.state.user?.role == 'ADMIN';
    final role = isAdmin ? 'ADMIN' : 'Organizador';
    final now = DateTime.now();
    final date = '${now.day} de ${_months[now.month - 1]} de ${now.year}';

    final quickActions = <_QuickAction>[
      _QuickAction(
        AppStrings.newCompetition,
        Icons.emoji_events_outlined,
        '/competitions/new',
      ),
      _QuickAction(
        AppStrings.newGame,
        Icons.sports_score_outlined,
        '/games/new',
      ),
      _QuickAction(
        AppStrings.importAthletes,
        Icons.upload_file_outlined,
        '/athletes/import',
      ),
      _QuickAction(
        AppStrings.newOrganization,
        Icons.business_outlined,
        '/organizations/new',
      ),
    ];

    final modules = <_MenuItem>[
      _MenuItem(Icons.business, AppStrings.organizations, '/organizations'),
      _MenuItem(
        Icons.emoji_events_outlined,
        AppStrings.competitions,
        '/competitions',
      ),
      _MenuItem(Icons.sports_soccer, AppStrings.venues, '/venues'),
      _MenuItem(Icons.person_outline, AppStrings.athletes, '/athletes'),
      _MenuItem(Icons.groups_outlined, AppStrings.rosters, '/rosters'),
      if (isAdmin)
        _MenuItem(Icons.fact_check_outlined, 'Aprovações', '/approvals'),
      if (isAdmin)
        _MenuItem(Icons.admin_panel_settings, AppStrings.users, '/users'),
    ];

    return AppScreen(
      title: 'Início',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WelcomeBand(name: userName ?? 'organizador', date: date, role: role),
              const SizedBox(height: 24),
              Text(
                AppStrings.quickActions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final action in quickActions)
                    FilledButton.icon(
                      onPressed: () => context.go(action.route),
                      icon: Icon(action.icon, size: 18),
                      label: Text(action.label),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.modules,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: wide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: wide ? 1.4 : 1.5,
                children: [
                  for (final module in modules)
                    _menuCard(
                      context,
                      icon: module.icon,
                      title: module.title,
                      onTap: () => context.go(module.route),
                    ),
                ],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Banda de boas-vindas do dashboard: "Olá, {nome}!" + data + papel.
class _WelcomeBand extends StatelessWidget {
  const _WelcomeBand({
    required this.name,
    required this.date,
    required this.role,
  });

  final String name;
  final String date;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.hello}, $name!',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.surface),
                ),
                const SizedBox(height: 8),
                Text(
                  '$date · $role',
                  style: TextStyle(
                    color: AppColors.surface.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.07,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.sports_score,
            size: 56,
            color: AppColors.surface.withValues(alpha: 0.25),
          ),
        ],
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

class _QuickAction {
  final String label;
  final IconData icon;
  final String route;

  const _QuickAction(this.label, this.icon, this.route);
}