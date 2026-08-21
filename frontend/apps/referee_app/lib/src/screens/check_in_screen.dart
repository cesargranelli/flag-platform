import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Check-in e validação de atletas por jogo (mesa).
///
/// Usa o mesmo contexto de jogo compartilhado da operação; lista agrupada por
/// time com contadores e estado por linha.
class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitions = ref.watch(competitionsProvider);
    final selectedComp = ref.watch(selectedCompetitionProvider);
    final selectedRound = ref.watch(selectedRoundProvider);
    final selectedGame = ref.watch(selectedGameProvider);

    final compData = competitions.valueOrNull ?? const [];
    final effectiveComp =
        selectedComp ?? (compData.isNotEmpty ? compData.first.id : null);

    // Fluxo único: campeonato → rodadas (categorias foram removidas, V24).
    final rounds = effectiveComp == null
        ? null
        : ref.watch(roundsProvider(effectiveComp));
    final roundData = rounds?.valueOrNull ?? const [];
    final effectiveRound =
        selectedRound ?? (roundData.isNotEmpty ? roundData.first.id : null);

    final games = effectiveRound == null
        ? null
        : ref.watch(gamesByRoundProvider(effectiveRound));
    final gamesData = games?.valueOrNull;
    final effectiveGameId =
        selectedGame ??
        (gamesData?.isNotEmpty == true ? gamesData!.first.id : null);
    Game? selectedGameObj;
    if (effectiveGameId != null && gamesData != null) {
      final matches = gamesData.where((g) => g.id == effectiveGameId);
      if (matches.isNotEmpty) selectedGameObj = matches.first;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in de atletas')),
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
              if (rounds != null) ...[
                const SizedBox(height: 12),
                rounds.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => AppErrorState(
                    message: 'Erro ao carregar rodadas',
                    onRetry: () =>
                        ref.invalidate(roundsProvider(effectiveComp!)),
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
                _buildRoster(context, ref, selectedGameObj),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compDropdown(List<Competition> items, String? value, WidgetRef ref) {
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
          .map(
            (r) => DropdownMenuItem(
              value: r.id,
              child: Text('Rodada ${r.number} - ${r.name}'),
            ),
          )
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
          .map(
            (g) => DropdownMenuItem(
              value: g.id,
              child: Text(
                '${g.homeTeamName ?? 'Casa'} x ${g.awayTeamName ?? 'Fora'} · '
                '${_formatDateTime(g.scheduledAt)} · ${g.status.name}',
              ),
            ),
          )
          .toList(),
      onChanged: (v) => ref.read(selectedGameProvider.notifier).state = v,
    );
  }

  Widget _buildRoster(BuildContext context, WidgetRef ref, Game game) {
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
        final home = items.where((c) => c.teamId == game.homeTeamId).toList();
        final away = items.where((c) => c.teamId == game.awayTeamId).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusCard(game),
            const SizedBox(height: 8),
            if (home.isNotEmpty) _teamSection(context, ref, home, inProgress),
            if (away.isNotEmpty) _teamSection(context, ref, away, inProgress),
          ],
        );
      },
    );
  }

  Widget _statusCard(Game game) {
    final present = 0; // atualizado por seção; simplificação visual
    return Card(
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
              '${_formatDateTime(game.scheduledAt)} · ${_gameStatusLabel(game.status)}'
              '${present > 0 ? '' : ''}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamSection(
    BuildContext context,
    WidgetRef ref,
    List<CheckIn> items,
    bool inProgress,
  ) {
    final teamName = items.first.teamName ?? 'Time';
    final present = items
        .where((c) => c.status == CheckInStatus.present)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$present/${items.length} presentes',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        for (final checkIn in items)
          _buildAthleteTile(context, ref, checkIn, inProgress),
      ],
    );
  }

  Widget _buildAthleteTile(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
    bool inProgress,
  ) {
    final statusLabel = switch (checkIn.status) {
      CheckInStatus.present => 'PRESENTE',
      CheckInStatus.noShow => 'FALTOU',
      CheckInStatus.notRegistered => 'FORA DO ROSTER',
      _ => '',
    };

    final hasOverride = checkIn.matchNumber != null;
    final numberText = checkIn.number != null ? 'Camisa ${checkIn.number}' : '';
    final officialText = hasOverride && checkIn.athleteNumber != null
        ? 'oficial ${checkIn.athleteNumber}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(checkIn.athleteName),
        subtitle: Text(
          '${numberText.isNotEmpty ? numberText : ''}'
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
              onPressed: () => _editMatchNumber(context, ref, checkIn),
            ),
            if (inProgress)
              FilledButton.tonal(
                onPressed: () => _validate(context, ref, checkIn),
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
                        _mark(context, ref, checkIn, CheckInStatus.present),
                  ),
                  IconButton(
                    tooltip: 'Não compareceu',
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () =>
                        _mark(context, ref, checkIn, CheckInStatus.noShow),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _mark(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
    CheckInStatus status,
  ) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível registrar o check-in'),
          ),
        );
      }
    }
  }

  Future<void> _validate(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
  ) async {
    try {
      final result = await ref
          .read(checkInApiProvider)
          .validate(gameId: checkIn.gameId, athleteId: checkIn.athleteId);
      if (context.mounted) {
        if (result.status == CheckInStatus.notRegistered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${checkIn.athleteName} não está no roster'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Atleta validado')));
        }
      }
      ref.invalidate(checkinProvider(checkIn.gameId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível validar o atleta')),
        );
      }
    }
  }

  Future<void> _editMatchNumber(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
  ) async {
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

    if (newNumber == null || !context.mounted) return;

    final int? number = newNumber == -1 ? null : newNumber;
    try {
      await ref
          .read(checkInApiProvider)
          .setMatchNumber(
            gameId: checkIn.gameId,
            athleteId: checkIn.athleteId,
            number: number,
          );
      ref.invalidate(checkinProvider(checkIn.gameId));
    } on RepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a numeração')),
        );
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
