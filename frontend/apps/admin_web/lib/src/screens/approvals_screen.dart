import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Tela exclusiva do super usuário (ADMIN) para aprovar/rejeitar contas.
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aprovações')),
      body: pending.when(
        loading: () => const AppLoading(message: 'Carregando pendências...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar as pendências',
          onRetry: () => ref.invalidate(pendingUsersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhuma conta aguardando aprovação',
              icon: Icons.verified_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final user = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(user.email),
                  subtitle: Text(
                    'Solicitado em ${_formatDateTime(user.createdAt)}',
                  ),
                  isThreeLine: false,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Rejeitar',
                        icon: const Icon(Icons.cancel, color: AppColors.danger),
                        onPressed: () =>
                            _reject(context, ref, user),
                      ),
                      IconButton(
                        tooltip: 'Aprovar',
                        icon: const Icon(Icons.check_circle,
                            color: AppColors.success),
                        onPressed: () => _approve(context, ref, user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, User user) async {
    try {
      await ref.read(authApiProvider).approveUser(user.id);
      ref.invalidate(pendingUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} aprovado!')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível aprovar.')),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, User user) async {
    try {
      await ref.read(authApiProvider).rejectUser(user.id);
      ref.invalidate(pendingUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.email} rejeitado.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível rejeitar.')),
        );
      }
    }
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'agora';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
