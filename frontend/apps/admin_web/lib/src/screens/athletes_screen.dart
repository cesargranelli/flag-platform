import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Gestão de atletas: cards e navegação para o detalhe.
class AthletesScreen extends ConsumerWidget {
  const AthletesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(athletesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atletas'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          IconButton(
            tooltip: 'Importar CSV',
            icon: const Icon(Icons.upload_file),
            onPressed: () => context.push('/athletes/import'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo atleta',
        onPressed: () => context.push('/athletes/new'),
        child: const Icon(Icons.add),
      ),
      body: athletes.when(
        loading: () => const AppLoading(message: 'Carregando atletas...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os atletas',
          onRetry: () => ref.invalidate(athletesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum atleta cadastrado',
              icon: Icons.person_outline,
            );
          }
          return AppLayout.content(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 600 ? 2 : 1;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 96,
                  ),
                  itemBuilder: (context, index) {
                    final athlete = items[index];
                    return _athleteCard(context, athlete);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _athleteCard(BuildContext context, Athlete athlete) {
    final position = athlete.position?.label ?? '';
    final subtitle = [
      if (athlete.number != null) '#${athlete.number}',
      if (position.isNotEmpty) position,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/athletes/${athlete.id}', extra: athlete),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _avatar(athlete, size: 48, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      athlete.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(Athlete athlete, {required double size, required double radius}) {
    final photo = athlete.photoUrl;
    final validPhoto = photo != null &&
        photo.isNotEmpty &&
        (Uri.tryParse(photo)?.hasScheme ?? false);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: validPhoto
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  _initials(athlete.name),
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.4),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(athlete.name),
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.4),
              ),
            ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
