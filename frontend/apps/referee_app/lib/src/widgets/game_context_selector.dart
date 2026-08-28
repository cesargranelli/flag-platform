import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/datetime_utils.dart';

/// Cascata de seleção do contexto de jogo (campeonato → rodada → jogo),
/// compartilhada entre a operação e o check-in (issue #425#10).
///
/// Encapsula os três dropdowns (padrão admin_web com `ValueKey`), os estados
/// de loading/erro/vazio e o reset em cascata. A seleção continua sendo a
/// fonte da verdade compartilhada via StateProviders
/// (`selectedCompetitionProvider`/`selectedRoundProvider`/`selectedGameProvider`).
///
/// O jogo NÃO é auto-selecionado: até o usuário escolher, um `AppEmptyState`
/// orientador é exibido no lugar das ações (issue #425#3). Quando há jogo
/// selecionado, [builder] é chamado com ele.
class GameContextSelector extends ConsumerWidget {
  const GameContextSelector({super.key, required this.builder});

  /// Constrói o conteúdo dependente do jogo selecionado.
  final Widget Function(BuildContext context, Game game) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionsAsync = ref.watch(competitionsProvider);
    return competitionsAsync.when(
      loading: () => const AppLoading(message: 'Carregando campeonatos...'),
      error: (error, stackTrace) => AppErrorState(
        message: 'Não foi possível carregar os campeonatos',
        onRetry: () => ref.invalidate(competitionsProvider),
      ),
      data: (compItems) {
        if (compItems.isEmpty) {
          return const AppEmptyState(
            message: 'Nenhum campeonato disponível',
            icon: Icons.emoji_events_outlined,
          );
        }
        return _cascade(context, ref, compItems);
      },
    );
  }

  Widget _cascade(
    BuildContext context,
    WidgetRef ref,
    List<Competition> compItems,
  ) {
    final selectedComp = ref.watch(selectedCompetitionProvider);
    final effectiveComp = selectedComp ?? compItems.first.id;

    final roundsAsync = ref.watch(roundsProvider(effectiveComp));
    final roundItems = roundsAsync.valueOrNull ?? const <Round>[];
    final selectedRound = ref.watch(selectedRoundProvider);
    final effectiveRound =
        selectedRound ?? (roundItems.isNotEmpty ? roundItems.first.id : null);

    final gamesAsync = effectiveRound == null
        ? null
        : ref.watch(gamesByRoundProvider(effectiveRound));
    final gameItems = gamesAsync?.valueOrNull ?? const <Game>[];
    final selectedGameId = ref.watch(selectedGameProvider);
    // Defensivo: só considera a seleção se o jogo ainda está na rodada.
    final String? effectiveGameId =
        selectedGameId != null && gameItems.any((g) => g.id == selectedGameId)
            ? selectedGameId
            : null;

    Game? selectedGameObj;
    if (effectiveGameId != null) {
      selectedGameObj = gameItems.firstWhere((g) => g.id == effectiveGameId);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('comp-$effectiveComp'),
          initialValue: effectiveComp,
          decoration: const InputDecoration(labelText: 'Campeonato'),
          items: [
            for (final c in compItems)
              DropdownMenuItem(
                value: c.id,
                child: appDropdownItem(Icons.emoji_events_outlined, c.name),
              ),
          ],
          onChanged: (value) {
            ref.read(selectedCompetitionProvider.notifier).state = value;
            ref.read(selectedRoundProvider.notifier).state = null;
            ref.read(selectedGameProvider.notifier).state = null;
          },
        ),
        const SizedBox(height: 12),
        _section(
          async: roundsAsync,
          loadingMessage: 'Carregando rodadas...',
          errorMessage: 'Não foi possível carregar as rodadas',
          onRetry: () => ref.invalidate(roundsProvider(effectiveComp)),
          empty: roundItems.isEmpty,
          emptyMessage: 'Nenhuma rodada disponível',
          emptyIcon: Icons.format_list_numbered,
          child: DropdownButtonFormField<String>(
            key: ValueKey('round-$effectiveRound'),
            initialValue: effectiveRound,
            decoration: const InputDecoration(labelText: 'Rodada'),
            items: [
              for (final r in roundItems)
                DropdownMenuItem(
                  value: r.id,
                  child: appDropdownItem(
                    Icons.format_list_numbered,
                    'Rodada ${r.number} - ${r.name}',
                  ),
                ),
            ],
            onChanged: (value) {
              ref.read(selectedRoundProvider.notifier).state = value;
              ref.read(selectedGameProvider.notifier).state = null;
            },
          ),
        ),
        if (effectiveRound != null) ...[
          const SizedBox(height: 12),
          _section(
            async: gamesAsync!,
            loadingMessage: 'Carregando jogos...',
            errorMessage: 'Não foi possível carregar os jogos',
            onRetry: () =>
                ref.invalidate(gamesByRoundProvider(effectiveRound)),
            empty: gameItems.isEmpty,
            emptyMessage: 'Nenhum jogo nesta rodada',
            emptyIcon: Icons.sports,
            child: DropdownButtonFormField<String>(
              key: ValueKey('game-$effectiveRound'),
              initialValue: effectiveGameId,
              hint: const Text('Selecione o jogo'),
              decoration: const InputDecoration(labelText: 'Jogo'),
              items: [
                for (final g in gameItems)
                  DropdownMenuItem(
                    value: g.id,
                    child: appDropdownItem(
                      Icons.sports,
                      '${g.homeTeamName ?? 'Casa'} x '
                      '${g.awayTeamName ?? 'Fora'} · '
                      '${formatDateTime(g.scheduledAt)} · ${g.status.label}',
                    ),
                  ),
              ],
              onChanged: (value) =>
                  ref.read(selectedGameProvider.notifier).state = value,
            ),
          ),
        ],
        if (selectedGameObj != null) ...[
          const SizedBox(height: 16),
          builder(context, selectedGameObj),
        ] else if (gameItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          const AppEmptyState(
            message: 'Selecione o jogo na rodada',
            icon: Icons.touch_app_outlined,
          ),
        ],
      ],
    );
  }

  /// Seção da cascata com estados de loading/erro/vazio (issue #425#11).
  ///
  /// Durante recarga com dados anteriores, mantém o dropdown visível com uma
  /// faixa de progresso sobreposta — a interface não "pula" (issue #425#24).
  Widget _section({
    required AsyncValue<dynamic> async,
    required String loadingMessage,
    required String errorMessage,
    required VoidCallback onRetry,
    required bool empty,
    required String emptyMessage,
    required IconData emptyIcon,
    required Widget child,
  }) {
    if (async.isLoading && !async.hasValue) {
      return AppLoading(message: loadingMessage);
    }
    if (async.hasError && !async.hasValue) {
      return AppErrorState(message: errorMessage, onRetry: onRetry);
    }
    if (empty) {
      return AppEmptyState(message: emptyMessage, icon: emptyIcon);
    }
    return Stack(
      children: [
        child,
        if (async.isLoading)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}