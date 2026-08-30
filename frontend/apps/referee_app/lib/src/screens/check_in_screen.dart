import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/game_context_card.dart';
import '../widgets/game_context_selector.dart';
import '../widgets/status_badges.dart';

/// Check-in e validação de atletas por jogo (mesa).
///
/// Usa o mesmo contexto de jogo compartilhado da operação
/// ([GameContextSelector]) — a cascata campeonato → rodada → jogo não é
/// duplicada aqui (issue #425#10). O roster é listado agrupado por time, com
/// contadores e estado visual por linha.
class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in de atletas'),
        actions: [
          // Atalho cruzado para a operação (issue #425#19).
          IconButton(
            tooltip: 'Operação de jogo',
            icon: const Icon(Icons.sports_score_outlined),
            onPressed: () => context.push('/operation'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameContextSelector(
              builder: (context, game) => _CheckInRoster(game: game),
            ),
          ],
        ),
      ),
    );
  }
}

/// Roster de check-in do jogo selecionado: resumo com contador agregado,
/// seções por time e ações por atleta.
class _CheckInRoster extends ConsumerWidget {
  const _CheckInRoster({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkins = ref.watch(checkinProvider(game.id));
    // Conferência de presença dos atletas permitida somente na abertura (OPEN).
    final canCheckIn = game.status == GameStatus.open;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameContextCard(game: game),
        const SizedBox(height: 16),
        checkins.when(
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
                _summaryCard(context, items),
                const SizedBox(height: 8),
                if (home.isNotEmpty)
                  _teamSection(context, ref, home, canCheckIn),
                if (away.isNotEmpty)
                  _teamSection(context, ref, away, canCheckIn),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Card de resumo do roster: contador global de presentes vs convocados
  /// computado dos dois times (issue #425#20) + barra de presença.
  Widget _summaryCard(BuildContext context, List<CheckIn> items) {
    final theme = Theme.of(context);
    final present = items
        .where((c) => c.status == CheckInStatus.present)
        .length;
    final ratio = items.isEmpty ? 0.0 : present / items.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_reg, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$present/${items.length} presentes',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: AppColors.success,
                backgroundColor: AppColors.disabled,
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
    bool canCheckIn,
  ) {
    final theme = Theme.of(context);
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
                child: Text(teamName, style: theme.textTheme.titleMedium),
              ),
              Text(
                '$present/${items.length} presentes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        for (final checkIn in items)
          _buildAthleteTile(context, ref, checkIn, canCheckIn),
      ],
    );
  }

  Widget _buildAthleteTile(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
    bool canCheckIn,
  ) {
    final theme = Theme.of(context);
    final hasOverride = checkIn.matchNumber != null;
    final details = <String>[
      if (checkIn.number != null) 'Camisa ${checkIn.number}',
      if (hasOverride && checkIn.athleteNumber != null)
        'oficial ${checkIn.athleteNumber}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(checkIn.athleteName, style: theme.textTheme.titleSmall),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  // `status` é nullable no domain; pendente é o estado inicial.
                  CheckInStatusBadge(
                    status: checkIn.status ?? CheckInStatus.pending,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _tileActions(context, ref, checkIn, canCheckIn),
          ],
        ),
      ),
    );
  }

  /// Ações do atleta: numeração sempre; durante a abertura (OPEN) a mesa
  /// confere a presença — "Validar" (troca por "Validado" desabilitado após
  /// validar, issue #425#6) e/ou marcação manual Presente/Presente.
  /// Fora de OPEN a conferência não é permitida (issue #488).
  Widget _tileActions(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
    bool canCheckIn,
  ) {
    final hasOverride = checkIn.matchNumber != null;
    final tagIcon = Icon(
      hasOverride ? Icons.tag : Icons.tag_outlined,
      color: hasOverride ? AppColors.textPrimary : null,
    );

    if (!canCheckIn) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Numeração da partida',
            icon: tagIcon,
            onPressed: () => _editMatchNumber(context, ref, checkIn),
          ),
        ],
      );
    }

    // Durante a abertura: aprovação de presença.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Numeração da partida',
              icon: tagIcon,
              onPressed: () => _editMatchNumber(context, ref, checkIn),
            ),
            if (checkIn.status == CheckInStatus.validated)
              FilledButton.tonalIcon(
                onPressed: null,
                icon: const Icon(Icons.check),
                label: const Text('Validado'),
              )
            else
              FilledButton.tonal(
                onPressed: () => _validate(context, ref, checkIn),
                child: const Text('Validar'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Presente',
              icon: const Icon(
                Icons.check_circle,
                color: AppColors.success,
              ),
              onPressed: () =>
                  _mark(context, ref, checkIn, CheckInStatus.present),
            ),
            IconButton(
              tooltip: 'Não compareceu',
              icon: const Icon(Icons.cancel, color: AppColors.danger),
              onPressed: () =>
                  _mark(context, ref, checkIn, CheckInStatus.noShow),
            ),
          ],
        ),
      ],
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
            backgroundColor: AppColors.danger,
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
              backgroundColor: AppColors.danger,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atleta validado'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      ref.invalidate(checkinProvider(checkIn.gameId));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível validar o atleta'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  /// Diálogo de numeração da partida com validação no campo (issue #425#22):
  /// vazio = usar oficial; senão, inteiro maior que 0.
  Future<void> _editMatchNumber(
    BuildContext context,
    WidgetRef ref,
    CheckIn checkIn,
  ) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(
      text: checkIn.matchNumber?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final newNumber = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Numeração da partida'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${checkIn.athleteName}\n'
                'Número oficial: ${checkIn.athleteNumber ?? '—'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              // Borda regida pelo InputDecorationTheme do tema (#25).
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número da partida',
                  hintText: 'Deixe vazio para usar o oficial',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null; // vazio = oficial
                  final parsed = int.tryParse(text);
                  if (parsed == null || parsed <= 0) {
                    return 'Use um número inteiro maior que 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final text = controller.text.trim();
                Navigator.pop(
                  dialogContext,
                  text.isEmpty ? -1 : int.parse(text),
                );
              }
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
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar a numeração'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}