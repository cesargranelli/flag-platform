import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Tela inicial do Admin Web — estrutura visual Kickster.
///
/// Layout:
/// - Header pessoal (via AppScreen): avatar + nome + greeting + bell
/// - Seção "Módulos": título 16px w600 + grid de KicksterCards
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(authControllerProvider.select((a) => a.state.user?.role)) ==
        UserRole.admin;

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seção "Módulos"
          _SectionHeader(title: 'Módulos'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
        ],
      ),
    );
  }
}

// ── Section header ──────────────────────────────────────────────────────────

/// Título de seção Kickster (Figma: "Live Matches" 16px w600 + "See All").
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// ── Module data ─────────────────────────────────────────────────────────────

class _Module {
  final IconData icon;
  final String title;
  final String route;

  const _Module(this.icon, this.title, this.route);
}
