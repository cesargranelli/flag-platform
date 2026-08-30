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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authControllerProvider).state.user?.role == 'ADMIN';
    final user = ref.watch(authControllerProvider).state.user;
    final showDisabled = isAdmin && _showDisabled;
    final competitions = showDisabled
        ? ref.watch(competitionsAdminProvider(true))
        : ref.watch(competitionsProvider);

    return AppScreen(
      title: 'Campeonatos',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem('Campeonatos'),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Actions
          Row(
            children: [
              const Spacer(),
              KicksterButton(
                label: 'Novo',
                icon: Icons.add,
                onPressed: () => context.go('/competitions/new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Conteúdo
          competitions.when(
            loading: () =>
                const AppLoading(message: 'Carregando campeonatos...'),
            error: (error, stackTrace) => AppErrorState(
              message: 'Não foi possível carregar os campeonatos',
              onRetry: () => showDisabled
                  ? ref.invalidate(competitionsAdminProvider(true))
                  : ref.invalidate(competitionsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return KicksterEmptyState(
                  icon: Icons.emoji_events_outlined,
                  message: 'Nenhum campeonato cadastrado',
                  description:
                      'Crie o primeiro campeonato para começar a usar.',
                  action: KicksterButton(
                    label: 'Criar campeonato',
                    icon: Icons.add,
                    onPressed: () => context.go('/competitions/new'),
                  ),
                );
              }
              final query = _query.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? items
                  : items
                      .where((c) => c.name.toLowerCase().contains(query))
                      .toList(growable: false);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Row(
                      children: [
                        if (query.isNotEmpty)
                          Text(
                            '${filtered.length} ${filtered.length == 1 ? 'resultado' : 'resultados'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
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
                              icon: const Icon(
                                  Icons.visibility_off_outlined),
                              tooltip: 'Desativados',
                              onPressed: () => setState(
                                  () => _showDisabled = !_showDisabled),
                            ),
                          ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 280,
                          child: KicksterSearchField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const AppEmptyState(
                      message: 'Nenhum campeonato encontrado',
                      icon: Icons.search_off,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns =
                            constraints.maxWidth >= 600 ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 96,
                          ),
                          itemBuilder: (context, index) {
                            final competition = filtered[index];
                            return _competitionCard(
                                context, competition, user);
                          },
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Card de campeonato no padrão Kickster (core #439): ícone do troféu,
  /// nome (+ organização como subtítulo) e menu de gestão para quem pode
  /// editar (#261). Badges de modalidade/gênero/faixa e status continuam
  /// visíveis no detalhe.
  Widget _competitionCard(BuildContext context, Competition competition, dynamic user) {
    final isDisabled = competition.status == CompetitionStatus.disabled;
    return KicksterCard(
      icon: Icons.emoji_events_outlined,
      title: competition.name,
      subtitle:
          (competition.organizationName?.isNotEmpty ?? false)
              ? competition.organizationName
              : null,
      onTap: () =>
          context.push('/competitions/${competition.id}', extra: competition),
      // Issue #261: ações de gestão (desativar/reativar) exigem
      // ser criador do campeonato ou ADMIN — o backend já bloqueia.
      trailing: canEditCompetition(
        user,
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
    return showKicksterConfirm(
      context: context,
      title: title,
      content: message,
      confirmLabel: 'Desativar',
      danger: true,
    );
  }

  void _invalidateLists() {
    ref.invalidate(competitionsProvider);
    ref.invalidate(competitionsAdminProvider(true));
  }

  Future<void> _deactivate(Competition competition) => _toggleActive(
        competition,
        activate: false,
        successMessage: '${competition.name} desativado.',
        errorMessage: 'Não foi possível desativar o campeonato.',
      );

  Future<void> _reactivate(Competition competition) => _toggleActive(
        competition,
        activate: true,
        successMessage: '${competition.name} reativado.',
        errorMessage: 'Não foi possível reativar o campeonato.',
      );

  Future<void> _toggleActive(
    Competition competition, {
    required bool activate,
    required String successMessage,
    required String errorMessage,
  }) async {
    try {
      if (activate) {
        await ref.read(competitionApiProvider).reactivate(competition.id);
      } else {
        await ref.read(competitionApiProvider).deactivate(competition.id);
      }
      _invalidateLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}
