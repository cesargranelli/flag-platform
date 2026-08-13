import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Tela inicial do Admin Web (painel do organizador).
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Bem-vindo, ${userName ?? 'organizador'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestão de cadastros do organizador',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
