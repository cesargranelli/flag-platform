import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Operação de partida ao vivo: seleciona o jogo (contexto compartilhado com
/// o check-in) e inicia/finaliza, com placar ao vivo.
class GameOperationScreen extends ConsumerWidget {
  const GameOperationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedComp = ref.watch(selectedCompetitionProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final selectedRound = ref.watch(selectedRoundProvider);
    final selectedGame = ref.watch(selectedGameProvider);

    final compData = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedComp ?? (compData.isNotEmpty ? compData.first.id : null);

    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));
    final catData = categories?.valueOrNull ?? const [];
    final effectiveCat =
        selectedCat ?? (catData.isNotEmpty ? catData.first.id : null);

    final rounds = effectiveCat == null
        ? null
        : ref.watch(roundsProvider(effectiveCat));
    final roundData = rounds?.valueOrNull ?? const [];
    final effectiveRound =
        selectedRound ?? (roundData.isNotEmpty ? roundData.first.id : null);

    final games = effectiveRound == null
        ? null
        : ref.watch(gamesByRoundProvider(effectiveRound));
    final gamesData = games?.valueOrNull;
    final effectiveGameId =
        selectedGame ?? (gamesData?.isNotEmpty == true ? gamesData!.first.id : null);
    Game? selectedGameObj;
    if (effectiveGameId != null && gamesData != null) {
      final matches = gamesData.where((g) => g.id == effectiveGameId);
      if (matches.isNotEmpty) selectedGameObj = matches.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Operação de jogo')),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (e, s) => AppErrorState(
          message: 'Não foi possível carregar os campeonatos',
          onRetry: () => ref.invalidate(competitionsProvider),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                _compDropdown(compData, effectiveComp, ref),
                if (categories != null) ...[
                  const SizedBox(height: 12),
                  categories.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => AppErrorState(
                      message: 'Erro ao carregar categorias',
                      onRetry: () =>
                          ref.invalidate(categoriesProvider(effectiveComp!)),
                    ),
                    data: (_) => _catDropdown(catData, effectiveCat, ref),
                  ),
                ],
                if (rounds != null) ...[
                  const SizedBox(height: 12),
                  rounds.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => AppErrorState(
                      message: 'Erro ao carregar rodadas',
                      onRetry: () => ref.invalidate(roundsProvider(effectiveCat!)),
                    ),
                    data: (_) => _roundDropdown(roundData, effectiveRound, ref),
                  ),
                ],
                if (games != null) ...[
                  const SizedBox(height: 12),
                  games.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => AppErrorState(
                      message: 'Erro ao carregar jogos',
                      onRetry: () =>
                          ref.invalidate(gamesByRoundProvider(effectiveRound!)),
                    ),
                    data: (_) => _gameDropdown(gamesData!, effectiveGameId, ref),
                  ),
                ],
                if (games != null) const SizedBox(height: 16),
                if (selectedGameObj != null)
                  _buildGameActions(context, ref, selectedGameObj),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compDropdown(
      List<Competition> items, String? value, WidgetRef ref) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Campeonato',
        border: OutlineInputBorder(),
      ),
      items: items
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) {
        ref.read(selectedCompetitionProvider.notifier).state = v;
        ref.read(selectedCategoryProvider.notifier).state = null;
        ref.read(selectedRoundProvider.notifier).state = null;
        ref.read(selectedGameProvider.notifier).state = null;
      },
    );
  }

  Widget _catDropdown(List<Category> items, String? value, WidgetRef ref) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Categoria',
        border: OutlineInputBorder(),
      ),
      items: items
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) {
        ref.read(selectedCategoryProvider.notifier).state = v;
        ref.read(selectedRoundProvider.notifier).state = null;
        ref.read(selectedGameProvider.notifier).state = null;
      },
    );
  }

  Widget _roundDropdown(List<Round> items, String? value, WidgetRef ref) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Rodada',
        border: OutlineInputBorder(),
      ),
      items: items
          .map((r) => DropdownMenuItem(
                value: r.id,
                child: Text('Rodada ${r.number} - ${r.name}'),
              ))
          .toList(),
      onChanged: (v) {
        ref.read(selectedRoundProvider.notifier).state = v;
        ref.read(selectedGameProvider.notifier).state = null;
      },
    );
  }

  Widget _gameDropdown(List<Game> items, String? value, WidgetRef ref) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Jogo',
        border: OutlineInputBorder(),
      ),
      items: items
          .map((g) => DropdownMenuItem(
                value: g.id,
                child: Text(
                  '${g.homeTeamName ?? 'Casa'} x ${g.awayTeamName ?? 'Fora'} · '
                  '${_formatDateTime(g.scheduledAt)} · ${g.status.name}',
                ),
              ))
          .toList(),
      onChanged: (v) =>
          ref.read(selectedGameProvider.notifier).state = v,
    );
  }

  Widget _buildGameActions(BuildContext context, WidgetRef ref, Game game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${game.homeTeamName ?? 'Casa'} x ${game.awayTeamName ?? 'Fora'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDateTime(game.scheduledAt)} · ${_gameStatusLabel(game.status)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (game.status == GameStatus.inProgress) ...[
          _buildScoreControls(context, ref, game),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Finalizar partida'),
            onPressed: () => _confirmFinish(context, ref, game),
          ),
        ] else if (game.status == GameStatus.scheduled)
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar partida'),
            onPressed: () => _confirmStart(context, ref, game),
          ),
      ],
    );
  }

  Widget _buildScoreControls(BuildContext context, WidgetRef ref, Game game) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _scoreTeam('Casa', game.homeScore ?? 0,
                    () => _addPoint(context, ref, game, game.homeTeamId!)),
                Text(
                  '${game.homeScore ?? 0} x ${game.awayScore ?? 0}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                _scoreTeam('Fora', game.awayScore ?? 0,
                    () => _addPoint(context, ref, game, game.awayTeamId!)),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Corrigir placar'),
              onPressed: () => _correctScore(context, ref, game),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreTeam(String label, int score, VoidCallback onAdd) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$score', style: const TextStyle(fontSize: 20)),
        IconButton(
          tooltip: '+1 $label',
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onAdd,
        ),
      ],
    );
  }

  Future<void> _addPoint(
      BuildContext context, WidgetRef ref, Game game, String teamId) async {
    try {
      await ref.read(gameApiProvider).addScoreEvent(game.id, teamId);
      ref.invalidate(gamesByRoundProvider(game.roundId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível registrar o ponto')),
        );
      }
    }
  }

  Future<void> _correctScore(
      BuildContext context, WidgetRef ref, Game game) async {
    final home = TextEditingController(text: (game.homeScore ?? 0).toString());
    final away = TextEditingController(text: (game.awayScore ?? 0).toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corrigir placar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: home,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Casa'),
            ),
            TextField(
              controller: away,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fora'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final h = int.tryParse(home.text) ?? 0;
      final a = int.tryParse(away.text) ?? 0;
      await ref
          .read(gameApiProvider)
          .correctScore(game.id, homeScore: h, awayScore: a);
      ref.invalidate(gamesByRoundProvider(game.roundId));
    }
    home.dispose();
    away.dispose();
  }

  Future<void> _confirmStart(
      BuildContext context, WidgetRef ref, Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar partida'),
        content: Text(
          'Iniciar "${game.homeTeamName ?? 'Casa'} x ${game.awayTeamName ?? 'Fora'}" '
          'agora?\n\n${_formatDateTime(game.scheduledAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(gameApiProvider).updateStatus(game.id, GameStatus.inProgress);
        ref.invalidate(gamesByRoundProvider(game.roundId));
      } on RepositoryException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível iniciar a partida')),
          );
        }
      }
    }
  }

  Future<void> _confirmFinish(
      BuildContext context, WidgetRef ref, Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar partida'),
        content: const Text('Tem certeza que deseja finalizar esta partida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(gameApiProvider).updateStatus(game.id, GameStatus.finished);
        ref.invalidate(gamesByRoundProvider(game.roundId));
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível finalizar a partida')),
          );
        }
      }
    }
  }

  String _gameStatusLabel(GameStatus status) => switch (status) {
        GameStatus.scheduled => 'Agendado',
        GameStatus.inProgress => 'Ao vivo',
        GameStatus.finished => 'Encerrado',
        GameStatus.cancelled => 'Cancelado',
      };
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
