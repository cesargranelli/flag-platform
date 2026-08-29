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
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/competitions/new'),
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
      ],
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
                          mainAxisExtent: 96,
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

  /// Card de campeonato no padrão Kickster (core #439): ícone do troféu,
  /// nome (+ organização como subtítulo) e menu de gestão para quem pode
  /// editar (#261). Badges de modalidade/gênero/faixa e status continuam
  /// visíveis no detalhe.
  Widget _competitionCard(BuildContext context, Competition competition) {
    final isDisabled = competition.status == CompetitionStatus.disabled;
    return KicksterCard(
      icon: Icons.emoji_events_outlined,
      title: competition.name,
      subtitle:
          (competition.organizationName?.isNotEmpty ?? false)
              ? competition.organizationName
              : null,
      onTap: () =>
          context.go('/competitions/${competition.id}', extra: competition),
      // Issue #261: ações de gestão (desativar/reativar) exigem
      // ser criador do campeonato ou ADMIN — o backend já bloqueia.
      trailing: canEditCompetition(
        ref.watch(authControllerProvider).state.user,
        competition,
      )
          ? PopupMenuButton<String>(
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
            )
          : null,
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
}
