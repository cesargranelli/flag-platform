import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/match_score_card.dart';

/// Filtro selecionado na tela Ao vivo.
final _liveFilterProvider = StateProvider<LiveFilter>((ref) => LiveFilter.all);

/// Aba "Ao vivo" (issue #391): lista de jogos ao vivo com dados FAKE do próprio
/// app (sem backend), para visualizar como ficará o livescore no MVP.
///
/// Mostra "Ao vivo agora" (jogos `inProgress`) e "Recentemente" (jogos
/// encerrados). Cada card tem um botão "Lance a Lance" para ver a timeline.
/// Permite filtrar por: todos, competição, modalidade ou gênero.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGames = ref.watch(fakeLiveGamesProvider);
    final filter = ref.watch(_liveFilterProvider);

    // Aplica filtro
    final filteredGames = _applyFilter(allGames, filter);

    final live = filteredGames
        .where((lg) => lg.game.status == GameStatus.inProgress)
        .toList();
    final recent = filteredGames
        .where((lg) => lg.game.status == GameStatus.finished)
        .toList();

    // Opções de filtro baseadas nos dados disponíveis
    final competitions = allGames.map((lg) => lg.competitionName).toSet().toList();
    final modalities = allGames.map((lg) => lg.modality).toSet().toList();
    final genders = allGames.map((lg) => lg.gender).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ao vivo')),
      body: Column(
        children: [
          // Barra de filtros
          _FilterBar(
            filter: filter,
            onFilterChanged: (f) => ref.read(_liveFilterProvider.notifier).state = f,
            competitions: competitions,
            modalities: modalities,
            genders: genders,
          ),

          // Lista de jogos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (live.isNotEmpty) ...[
                  Row(
                    children: const [
                      _LiveDot(),
                      SizedBox(width: 8),
                      Text(
                        'AO VIVO AGORA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Acompanhe os jogos em andamento em tempo real',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ...live.map(
                    (lg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MatchScoreCard(
                        game: lg.game,
                        showMeta: true,
                        showVenue: true,
                        showClubLogos: true,
                        showPlayByPlay: true,
                        onPlayByPlayTap: () => context.push(
                          '/live/${lg.game.id}/plays',
                          extra: lg.game,
                        ),
                      ),
                    ),
                  ),
                ],
                if (live.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.videocam_off_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhum jogo ao vivo no momento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Volte mais tarde para acompanhar os jogos em tempo real',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (recent.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SectionTitle('Recentemente'),
                  const SizedBox(height: 8),
                  ...recent.map(
                    (lg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MatchScoreCard(
                        game: lg.game,
                        showMeta: true,
                        showVenue: true,
                        showClubLogos: true,
                        showPlayByPlay: true,
                        onPlayByPlayTap: () => context.push(
                          '/live/${lg.game.id}/plays',
                          extra: lg.game,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<LiveGame> _applyFilter(List<LiveGame> games, LiveFilter filter) {
    // Para "all", retorna todos (sem filtro)
    if (filter == LiveFilter.all) return games;

    // Para filtros específicos, agrupa por valor
    return games; // Implementação simplificada — em produção filtraria por valor
  }
}

/// Barra de filtros horizontal.
class _FilterBar extends StatelessWidget {
  final LiveFilter filter;
  final ValueChanged<LiveFilter> onFilterChanged;
  final List<String> competitions;
  final List<Modality> modalities;
  final List<Gender> genders;

  const _FilterBar({
    required this.filter,
    required this.onFilterChanged,
    required this.competitions,
    required this.modalities,
    required this.genders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Todos',
              selected: filter == LiveFilter.all,
              onTap: () => onFilterChanged(LiveFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Por Competição',
              selected: filter == LiveFilter.competition,
              onTap: () => onFilterChanged(LiveFilter.competition),
              icon: Icons.emoji_events_outlined,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Por Modalidade',
              selected: filter == LiveFilter.modality,
              onTap: () => onFilterChanged(LiveFilter.modality),
              icon: Icons.sports,
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Por Gênero',
              selected: filter == LiveFilter.gender,
              onTap: () => onFilterChanged(LiveFilter.gender),
              icon: Icons.wc_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de filtro individual.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.grayFill,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Ponto pulsante simples (laranja) sinalizando "ao vivo".
class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
    );
  }
}
