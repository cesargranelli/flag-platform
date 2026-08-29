import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela inicial do Admin Web (issue #433): grade de cards no estilo Kickster.
///
/// Sem banda de boas-vindas, sem ações rápidas e sem título de página: cada
/// card tem ícone grande + título do módulo, com raio 12 e fundo `surface`
/// (elevação sutil). A navegação entre módulos é feita por aqui — o header
/// global ficou apenas com marca + usuário. Grade responsiva: `>=960px` → 4
/// colunas; abaixo → 2 colunas.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin =
        ref.watch(authControllerProvider).state.user?.role == 'ADMIN';

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
      _Module(Icons.groups_outlined, AppStrings.rosters, '/rosters'),
      if (isAdmin)
        _Module(Icons.fact_check_outlined, 'Aprovações', '/approvals'),
      if (isAdmin)
        _Module(Icons.admin_panel_settings, AppStrings.users, '/users'),
    ];

    return Scaffold(
      body: SafeArea(
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
                  _KicksterCard(
                    icon: module.icon,
                    title: module.title,
                    onTap: () => context.go(module.route),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Card de módulo no estilo do kit Kickster (issue #433).
///
/// Raio 12, fundo `surface` branco com elevação sutil; ícone grande em
/// `primary` sobre um círculo `primary` @10% centralizado acima do título.
/// Sem descrição — estrutura simples, como no kit.
class _KicksterCard extends StatelessWidget {
  const _KicksterCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
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
                      color: AppColors.textPrimary,
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

class _Module {
  final IconData icon;
  final String title;
  final String route;

  const _Module(this.icon, this.title, this.route);
}