import 'package:flag_api/flag_api.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Operação de partida ao vivo: seleciona o jogo e inicia/finaliza.
class GameOperationScreen extends ConsumerStatefulWidget {
  const GameOperationScreen({super.key});

  @override
  ConsumerState<GameOperationScreen> createState() => _GameOperationScreenState();
}

class _GameOperationScreenState extends ConsumerState<GameOperationScreen> {
  String? _competitionId;
  String? _categoryId;
  String? _roundId;
  String? _gameId;
  bool _submitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final competitions = ref.watch(competitionsProvider);
    final compData = competitions.valueOrNull ?? const [];
    final effectiveComp =
        _competitionId ?? (compData.isNotEmpty ? compData.first.id : null);

    final categories = effectiveComp == null
        ? null
        : ref.watch(categoriesProvider(effectiveComp));
    final catData = categories?.valueOrNull ?? const [];
    final effectiveCat =
        _categoryId ?? (catData.isNotEmpty ? catData.first.id : null);

    final rounds = effectiveCat == null
        ? null
        : ref.watch(roundsProvider(effectiveCat));
    final roundData = rounds?.valueOrNull ?? const [];
    final effectiveRound =
        _roundId ?? (roundData.isNotEmpty ? roundData.first.id : null);

    final games = effectiveRound == null
        ? null
        : ref.watch(gamesByRoundProvider(effectiveRound));
    final gamesData = games?.valueOrNull;
    final effectiveGameId =
        _gameId ?? (gamesData?.isNotEmpty == true ? gamesData!.first.id : null);
    Game? selectedGame;
    if (effectiveGameId != null && gamesData != null) {
      final matches = gamesData.where((g) => g.id == effectiveGameId);
      if (matches.isNotEmpty) selectedGame = matches.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Operação de jogo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            competitions.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => const Text('Erro ao carregar campeonatos'),
              data: (_) => DropdownButtonFormField<String>(
                initialValue: effectiveComp,
                decoration: const InputDecoration(
                  labelText: 'Campeonato',
                  border: OutlineInputBorder(),
                ),
                items: compData
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _competitionId = value;
                  _categoryId = null;
                  _roundId = null;
                  _gameId = null;
                }),
              ),
            ),
            const SizedBox(height: 12),
            if (categories != null)
              categories.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar categorias'),
                data: (_) => DropdownButtonFormField<String>(
                  initialValue: effectiveCat,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: catData
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _categoryId = value;
                    _roundId = null;
                    _gameId = null;
                  }),
                ),
              ),
            if (categories != null) const SizedBox(height: 12),
            if (rounds != null)
              rounds.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar rodadas'),
                data: (_) => DropdownButtonFormField<String>(
                  initialValue: effectiveRound,
                  decoration: const InputDecoration(
                    labelText: 'Rodada',
                    border: OutlineInputBorder(),
                  ),
                  items: roundData
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text('Rodada ${r.number} - ${r.name}'),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _roundId = value;
                    _gameId = null;
                  }),
                ),
              ),
            if (rounds != null) const SizedBox(height: 12),
            if (games != null)
              games.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => const Text('Erro ao carregar jogos'),
                data: (_) => DropdownButtonFormField<String>(
                  initialValue: effectiveGameId,
                  decoration: const InputDecoration(
                    labelText: 'Jogo',
                    border: OutlineInputBorder(),
                  ),
                  items: gamesData!
                      .map((g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(
                              '${g.homeTeamName ?? 'Casa'} x ${g.awayTeamName ?? 'Fora'} · '
                              '${_formatDateTime(g.scheduledAt)} · ${g.status.name}',
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _gameId = value),
                ),
              ),
            if (games != null) const SizedBox(height: 16),
            if (selectedGame != null) _buildGameActions(selectedGame),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameActions(Game game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Status: ${game.status.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (game.status == GameStatus.inProgress) ...[
          _buildScoreControls(game),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Finalizar partida'),
            onPressed: _submitting ? null : () => _confirmFinish(game),
          ),
        ] else if (game.status == GameStatus.scheduled)
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar partida'),
            onPressed: _submitting ? null : () => _changeStatus(game, GameStatus.inProgress),
          ),
      ],
    );
  }

  Widget _buildScoreControls(Game game) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _scoreTeam('Casa', game.homeScore ?? 0, () => _addPoint(game, game.homeTeamId!)),
                Text(
                  '${game.homeScore ?? 0} x ${game.awayScore ?? 0}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                _scoreTeam('Fora', game.awayScore ?? 0, () => _addPoint(game, game.awayTeamId!)),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Corrigir placar'),
              onPressed: () => _correctScore(game),
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

  Future<void> _addPoint(Game game, String teamId) async {
    setState(() => _submitting = true);
    try {
      await ref.read(gameApiProvider).addScoreEvent(game.id, teamId);
      ref.invalidate(gamesByRoundProvider(game.roundId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível registrar o ponto')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _correctScore(Game game) async {
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

  Future<void> _changeStatus(Game game, GameStatus status) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(gameApiProvider).updateStatus(game.id, status);
      ref.invalidate(gamesByRoundProvider(game.roundId));
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível atualizar o status.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmFinish(Game game) async {
    final confirm = await showDialog<bool>(
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
    if (confirm == true) {
      await _changeStatus(game, GameStatus.finished);
    }
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
