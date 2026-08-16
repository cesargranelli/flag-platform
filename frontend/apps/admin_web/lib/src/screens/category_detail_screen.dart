import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Detalhe de uma categoria: apresenta os dados e oferece editar/excluir.
///
/// A exclusão é lógica (soft delete no backend) e mora aqui, com confirmação
/// e tratamento de erro.
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, this.categoryId, this.category});

  final String? categoryId;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catFuture = category != null
        ? null
        : ref.watch(categoryProvider(categoryId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? 'Categoria'),
        leading: const BackButton(),
      ),
      body: catFuture == null
          ? _buildDetail(context, ref, category!)
          : catFuture.when(
              loading: () => const AppLoading(message: 'Carregando categoria...'),
              error: (error, stackTrace) => AppErrorState(
                message: 'Não foi possível carregar a categoria',
                onRetry: () => ref.invalidate(categoryProvider(categoryId!)),
              ),
              data: (cat) => _buildDetail(context, ref, cat),
            ),
    );
  }

  Widget _buildDetail(BuildContext context, WidgetRef ref, Category category) {
    final competitions = ref.watch(competitionsProvider);
    final competitionName = competitions.valueOrNull
            ?.where((c) => c.id == category.competitionId)
            .map((c) => c.name)
            .firstOrNull ??
        '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppLayout.detail(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.category_outlined,
                              color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (competitionName.isNotEmpty)
                                Text(
                                  competitionName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push(
                              '/categories/${category.id}/edit',
                              extra: category,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar dados'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context, ref, category),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(
              'Informações',
              [
                _row('Nome', category.name),
                if (competitionName.isNotEmpty)
                  _row('Campeonato', competitionName),
                _row('Criada em', _formatDate(category.createdAt)),
                _row('Atualizada em', _formatDate(category.updatedAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          'Excluir a categoria "${category.name}"?\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(categoryApiProvider).delete(category.id);
      ref.invalidate(categoriesProvider(category.competitionId));
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Categoria "${category.name}" excluída')),
        );
        context.pop();
      }
    } on RepositoryException catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Não foi possível excluir a categoria. '
                  'Verifique se há times ou rodadas vinculados.')),
        );
      }
    }
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
