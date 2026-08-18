import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Check-in e validação de atletas por jogo (mesa).
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  String? _competitionId;
  String? _categoryId;
  String? _roundId;
  String? _gameId;
  bool _submitting = false;

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
      appBar: AppBar(title: const Text('Check-in de atletas')),
      body: competitions.when(
        loading: () => const AppLoading(message: 'Carregando campeonatos...'),
        error: (e, s) => const Text('Erro ao carregar campeonatos'),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
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
              if (selectedGame != null) _buildRoster(selectedGame),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoster(Game game) {
    final checkins = ref.watch(checkinProvider(game.id));
    final inProgress = game.status == GameStatus.inProgress;

    return checkins.when(
      loading: () => const AppLoading(message: 'Carregando roster...'),
      error: (e, s) => AppErrorState(
        message: 'Não foi possível carregar o check-in',
        onRetry: () => ref.invalidate(checkinProvider(game.id)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(
            message: 'Nenhum atleta nos times',
            icon: Icons.groups_outlined,
          );
        }
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
            const SizedBox(height: 8),
            for (final checkIn in items) _buildAthleteTile(checkIn, inProgress),
          ],
        );
      },
    );
  }

  Widget _buildAthleteTile(CheckIn checkIn, bool inProgress) {
    final statusLabel = switch (checkIn.status) {
      CheckInStatus.present => 'PRESENTE',
      CheckInStatus.noShow => 'FALTOU',
      CheckInStatus.notRegistered => 'FORA DO ROSTER',
      _ => '',
    };

    final hasOverride = checkIn.matchNumber != null;
    final numberText = checkIn.number != null ? 'Camisa ${checkIn.number}' : '';
    final officialText =
        hasOverride && checkIn.athleteNumber != null ? 'oficial ${checkIn.athleteNumber}' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(checkIn.athleteName),
        subtitle: Text(
          '${checkIn.teamName ?? ''}'
          '${numberText.isNotEmpty ? ' · $numberText' : ''}'
          '${officialText.isNotEmpty ? ' · $officialText' : ''}'
          '${statusLabel.isNotEmpty ? ' · $statusLabel' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Numeração da partida',
              icon: Icon(
                hasOverride ? Icons.tag : Icons.tag_outlined,
                color: hasOverride ? Colors.orange : null,
              ),
              onPressed: () => _editMatchNumber(checkIn),
            ),
            if (_submitting)
              const SizedBox(
                height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else if (inProgress)
              FilledButton.tonal(
                onPressed: () => _validate(checkIn),
                child: const Text('Validar'),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Presente',
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () =>
                        _mark(checkIn, CheckInStatus.present),
                  ),
                  IconButton(
                    tooltip: 'Não compareceu',
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _mark(checkIn, CheckInStatus.noShow),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMatchNumber(CheckIn checkIn) async {
    final controller = TextEditingController(
      text: checkIn.matchNumber?.toString() ?? '',
    );
    final newNumber = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Numeração da partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${checkIn.athleteName}\nNúmero oficial: ${checkIn.athleteNumber ?? '—'}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número da partida',
                hintText: 'Deixe vazio para usar o oficial',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(context, text.isEmpty ? -1 : int.tryParse(text));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (newNumber == null || !mounted) return;

    final int? number = newNumber == -1 ? null : newNumber;
    setState(() => _submitting = true);
    try {
      await ref.read(checkInApiProvider).setMatchNumber(
            gameId: checkIn.gameId,
            athleteId: checkIn.athleteId,
            number: number,
          );
      ref.invalidate(checkinProvider(checkIn.gameId));
    } on RepositoryException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a numeração')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _mark(CheckIn checkIn, CheckInStatus status) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(checkInApiProvider)
          .checkin(
            gameId: checkIn.gameId,
            athleteId: checkIn.athleteId,
            status: status,
          );
      ref.invalidate(checkinProvider(checkIn.gameId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível registrar o check-in')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _validate(CheckIn checkIn) async {
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(checkInApiProvider)
          .validate(gameId: checkIn.gameId, athleteId: checkIn.athleteId);
      if (mounted) {
        if (result.status == CheckInStatus.notRegistered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${checkIn.athleteName} não está no roster'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Atleta validado')),
          );
        }
      }
      ref.invalidate(checkinProvider(checkIn.gameId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível validar o atleta')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

String _formatDateTime(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
