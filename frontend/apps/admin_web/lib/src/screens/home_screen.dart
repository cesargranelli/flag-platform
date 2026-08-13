import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela inicial do Admin Web: menu de gestão do organizador.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Web'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Bem-vindo, ${userName ?? 'organizador'}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _menuItem(
            context,
            icon: Icons.business,
            title: 'Organizações',
            subtitle: 'Criar e editar organizações',
            onTap: () => context.push('/organizations'),
          ),
          _menuItem(
            context,
            icon: Icons.emoji_events_outlined,
            title: 'Campeonatos',
            subtitle: 'Criar e editar campeonatos',
            onTap: () => context.push('/competitions'),
          ),
          _menuItem(
            context,
            icon: Icons.category_outlined,
            title: 'Categorias',
            subtitle: 'Criar e editar categorias',
            onTap: () => context.push('/categories'),
          ),
          _menuItem(
            context,
            icon: Icons.sports_soccer,
            title: 'Campos',
            subtitle: 'Criar e editar campos de jogo',
            onTap: () => context.push('/venues'),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
