import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Tela inicial do Admin Web — estrutura visual Kickster (Figma 34417:1519).
///
/// Layout:
/// 1. **Header pessoal**: avatar 40px + nome w600 + greeting w400 + bell icon
/// 2. **Card destaque**: card grande r=12 com fundo primary, boas-vindas
/// 3. **Seção "Módulos"**: título 16px w600 + grid de KicksterCards
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).state;
    final isAdmin = authState.user?.role == 'ADMIN';
    final name = (authState.user?.name ?? '').trim();
    final email = (authState.user?.email ?? '').trim();

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

    final initials = _initials(name);

    return AppScreen(
      title: 'Início',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Header pessoal (Kickster: profile image + name + greeting + bell)
          _HomeHeader(
            name: name,
            email: email,
            initials: initials,
          ),
          const SizedBox(height: 24),

          // ── 2. Card destaque (Kickster: featured match card)
          _FeaturedCard(name: name),
          const SizedBox(height: 24),

          // ── 3. Seção "Módulos" (Kickster: section title + content)
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

// ── Header pessoal ──────────────────────────────────────────────────────────

/// Header da home seguindo o padrão Kickster (Figma 34417:1519):
/// Avatar 40px + Column[nome w600, greeting w400] + Spacer + bell icon.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.email,
    required this.initials,
  });

  final String name;
  final String email;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name : email;
    final greeting = name.isNotEmpty ? 'Olá, bem-vindo!' : 'Bem-vindo!';

    return Row(
      children: [
        // Avatar (Kickster: Profile Image 40x40)
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: initials.isNotEmpty
              ? Text(
                  initials,
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

        // Nome + Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
        ),

        // Notificações (Kickster: bell 24x24 + red dot + settings)
        _NotificationButton(),
      ],
    );
  }
}

/// Botão de notificação (Kickster: bell icon com dot vermelho).
class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sem notificações novas')),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          // Red dot (Kickster: Ellipse 6x6 fill=#e53935)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card destaque ───────────────────────────────────────────────────────────

/// Card destaque (Kickster: featured match card r=12, fundo primary).
///
/// No contexto admin, exibe uma mensagem de boas-vindas sobre fundo primary
/// com o nome do usuário.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isNotEmpty ? name.split(' ').first : 'Admin';

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern (subtle)
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de saudação (Kickster: date badge r=6)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Bem-vindo de volta',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Título principal
                Text(
                  'Olá, $displayName!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtítulo
                Text(
                  'Gerencie suas organizações, campeonatos e times.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
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
        TextButton(
          onPressed: () {},
          child: const Text(
            'Ver todos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
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
