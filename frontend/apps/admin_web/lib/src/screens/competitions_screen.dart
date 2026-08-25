import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';

/// Gestão de campeonatos: cards de acesso e navegação para o detalhe.
///
/// Listagem em grid de cards (padrão web); clicar navega para a tela de
/// detalhe do campeonato. ADMIN pode exibir desativados e gerenciá-los.
class CompetitionsScreen extends ConsumerStatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  ConsumerState<CompetitionsScreen> createState() =>
      _CompetitionsScreenState();
}

class _CompetitionsScreenState extends ConsumerState<CompetitionsScreen> {
  bool _showDisabled = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authControllerProvider).state.user?.role == 'ADMIN';
    final showDisabled = isAdmin && _showDisabled;
    final competitions = showDisabled
        ? ref.watch(competitionsAdminProvider(true))
        : ref.watch(competitionsProvider);

    return AppScreen(
      title: 'Campeonatos',
      leading: BackButton(onPressed: () => context.go('/')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo campeonato',
        onPressed: () => context.push('/competitions/new'),
        child: const Icon(Icons.add),
      ),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => showDisabled
              ? ref.invalidate(competitionsAdminProvider(true))
              : ref.invalidate(competitionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato cadastrado',
              icon: Icons.emoji_events_outlined,
            );
          }
          return AppLayout.content(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        '${items.length} campeonatos',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (isAdmin)
                        Tooltip(
                          message: 'Exibir campeonatos desativados',
                          child: IconButton(
                            isSelected: _showDisabled,
                            selectedIcon: const Icon(Icons.visibility),
                            icon: const Icon(Icons.visibility_off_outlined),
                            tooltip: 'Desativados',
                            onPressed: () =>
                                setState(() => _showDisabled = !_showDisabled),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 600 ? 2 : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          // 156: margem do Card (8) + padding (32) + 4 linhas
                          // de conteúdo (nome ~19 + org ~16 + badges ~18–42
                          // com quebra do Wrap + status ~18) + gaps (12) +
                          // folga p/ métricas de fonte. Extent fixo mantido
                          // pela performance do grid.
                          mainAxisExtent: 156,
                        ),
                        itemBuilder: (context, index) {
                          final competition = items[index];
                          return _competitionCard(context, competition);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _competitionCard(BuildContext context, Competition competition) {
    final isDisabled = competition.status == CompetitionStatus.disabled;
    final badges = <String>[
      if (competition.modality != null) competition.modality!.label,
      if (competition.gender != null) _genderLabel(competition.gender!),
      // Null-aware: valor ausente/desconhecido simplesmente omite a badge.
      ?_ageGroupLabel(competition.ageGroup),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push('/competitions/${competition.id}', extra: competition),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      competition.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDisabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration:
                            isDisabled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (competition.organizationName?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 2),
                      Text(
                        competition.organizationName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (badges.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final label in badges) _attributeBadge(label),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    _statusChip(competition.status),
                  ],
                ),
              ),
              // Issue #261: ações de gestão (desativar/reativar) exigem
              // ser criador do campeonato ou ADMIN — o backend já bloqueia.
              if (canEditCompetition(
                ref.watch(authControllerProvider).state.user,
                competition,
              ))
                PopupMenuButton<String>(
                  tooltip: 'Ações',
                  onSelected: (value) async {
                    if (value == 'deactivate') {
                      final ok = await _confirm(
                        context,
                        'Desativar campeonato',
                        '"${competition.name}" ficará invisível para os '
                            'demais usuários até ser reativado.',
                      );
                      if (ok == true) await _deactivate(competition);
                    } else if (value == 'reactivate') {
                      await _reactivate(competition);
                    }
                  },
                  itemBuilder: (_) => [
                    if (!isDisabled)
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: Text('Desativar'),
                      ),
                    if (isDisabled)
                      const PopupMenuItem(
                        value: 'reactivate',
                        child: Text('Reativar'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  void _invalidateLists() {
    ref.invalidate(competitionsProvider);
    ref.invalidate(competitionsAdminProvider(true));
  }

  Future<void> _deactivate(Competition competition) async {
    try {
      await ref.read(competitionApiProvider).deactivate(competition.id);
      _invalidateLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${competition.name} desativado.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível desativar o campeonato.')),
        );
      }
    }
  }

  Future<void> _reactivate(Competition competition) async {
    try {
      await ref.read(competitionApiProvider).reactivate(competition.id);
      _invalidateLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${competition.name} reativado.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível reativar o campeonato.')),
        );
      }
    }
  }

  /// Badge leve de atributo (modalidade, gênero, faixa etária), no mesmo
  /// padrão estrutural do [_statusChip] (Container + BoxDecoration raio 10).
  /// Substitui o widget Material `Chip`, cuja altura mínima e largura
  /// intrínseca causavam overflow nos cards estreitos do grid.
  Widget _attributeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.primary),
      ),
    );
  }

  String _genderLabel(String gender) => switch (gender) {
        'MALE' => 'Masculino',
        'FEMALE' => 'Feminino',
        _ => 'Misto',
      };

  /// Mapeamento tolerante: valor desconhecido vindo da API apenas omite a
  /// badge (o enum `AgeGroup.fromJson` lançaria exceção e derrubaria a lista).
  String? _ageGroupLabel(String? ageGroup) => switch (ageGroup) {
        'SUB11' => 'Sub-11',
        'SUB13' => 'Sub-13',
        'SUB14' => 'Sub-14',
        'SUB15' => 'Sub-15',
        'SUB17' => 'Sub-17',
        'SUB20' => 'Sub-20',
        'ADULT' => 'Adulto',
        'MASTER' => 'Master',
        'OPEN' => 'Livre',
        _ => null,
      };

  Widget _statusChip(CompetitionStatus status) {
    final (label, color) = switch (status) {
      CompetitionStatus.draft => ('Rascunho', AppColors.textSecondary),
      CompetitionStatus.published => ('Publicado', AppColors.success),
      CompetitionStatus.finished => ('Encerrado', AppColors.danger),
      CompetitionStatus.disabled => ('Desativado', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
