import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/competition_card.dart';
import 'competition_games_screen.dart';
import 'competition_results_screen.dart';
import 'competition_standings_screen.dart';

/// Hub do campeonato em foco (issue #389): container com `TabBar`.
///
/// A aba Campeonato mostra a lista de campeonatos ao abrir (quando não há
/// campeonato em foco). Ao selecionar um campeonato, exibe o hub com três abas:
/// Jogos, Resultados e Classificação. O botão "Trocar" volta para a lista
/// dentro da mesma aba.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  /// Id vindo da rota (`/competition/:id`); `null` na rota `/competition`.
  final String? competitionId;

  /// Nome vindo via `extra` (ou `null` em deep links).
  final String? competitionName;

  /// Aba inicial (0=Jogos, 1=Resultados, 2=Classificação) — permite que os
  /// deep links `/competition/:id/{games|results|standings}` abram a aba certa.
  final int initialTab;

  const CompetitionDetailScreen({
    super.key,
    this.competitionId,
    this.competitionName,
    this.initialTab = 0,
  });

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    // Deep link / rota direta de um campeonato define o "campeonato em foco".
    final id = widget.competitionId;
    if (id != null && id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = ref.read(focusedCompetitionProvider);
        if (current?.id != id) {
          ref.read(focusedCompetitionProvider.notifier).set(
            (id: id, name: widget.competitionName ?? current?.name ?? ''),
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant CompetitionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Navegar entre os deep links do hub (games/results/standings) sem
    // remontar o widget: sincroniza a aba inicial.
    if (widget.initialTab != _tabController.index) {
      _tabController.index = widget.initialTab;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(focusedCompetitionProvider);
    final id = widget.competitionId ?? focus?.id;
    final name = (widget.competitionName?.isNotEmpty ?? false)
        ? widget.competitionName!
        : (focus?.name ?? '');

    // Sem campeonato em foco e sem id na rota → orientador para escolher.
    if (id == null || id.isEmpty) {
      return _buildEmpty(context);
    }

    final title = name.isEmpty ? id : name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(focusedCompetitionProvider.notifier).set(null);
              context.go('/competition');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.swap_horiz, size: 20),
            label: const Text('Trocar'),
          ),
        ],
      ),
      body: AppLayout.content(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Jogos'),
                Tab(text: 'Resultados'),
                Tab(text: 'Classificação'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CompetitionGamesScreen(
                    competitionId: id,
                    competitionName: name,
                  ),
                  CompetitionResultsScreen(
                    competitionId: id,
                    competitionName: name,
                  ),
                  CompetitionStandingsScreen(
                    competitionId: id,
                    competitionName: name,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de campeonatos exibida quando nenhum campeonato está em foco.
  Widget _buildEmpty(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campeonatos')),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (error, stackTrace) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'Nenhum campeonato disponível',
              icon: Icons.sports_football,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final competition = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CompetitionCard(
                  competition: competition,
                  onTap: () {
                    ref.read(focusedCompetitionProvider.notifier).set(
                      (id: competition.id, name: competition.name),
                    );
                    context.go('/competition/${competition.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
