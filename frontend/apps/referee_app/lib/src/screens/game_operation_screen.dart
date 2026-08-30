import 'dart:async';

import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/datetime_utils.dart';
import '../widgets/game_context_card.dart';
import '../widgets/game_context_selector.dart';

/// Operação de partida ao vivo: seleciona o jogo (contexto compartilhado com
/// o check-in) e inicia/finaliza, com placar ao vivo.
class GameOperationScreen extends ConsumerWidget {
  const GameOperationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operação de jogo'),
        // A conferência de atletas é acessada pelo painel, somente quando a
        // partida estiver aberta (OPEN) — issue #490.
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameContextSelector(
              builder: (context, game) => GameOperationPanel(game: game),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painel de operação do jogo selecionado: inicia/finaliza, controles de
/// placar e timeline — com auto-refresh de 10s durante jogos ao vivo.
class GameOperationPanel extends ConsumerStatefulWidget {
  const GameOperationPanel({super.key, required this.game});

  final Game game;

  @override
  ConsumerState<GameOperationPanel> createState() =>
      _GameOperationPanelState();
}

class _GameOperationPanelState extends ConsumerState<GameOperationPanel> {
  Timer? _autoRefreshTimer;

  /// Time com POST de ponto em andamento — trava o "+1" (issue #425#8).
  String? _busyTeamId;

  @override
  void initState() {
    super.initState();
    _syncAutoRefresh();
  }

  @override
  void didUpdateWidget(covariant GameOperationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id ||
        oldWidget.game.status != widget.game.status) {
      _syncAutoRefresh();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// Auto-refresh de 10s apenas durante jogos ao vivo (padrão public_app,
  /// issue #425#18). Invalida o jogo e os eventos de pontuação (#1).
  void _syncAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (widget.game.status != GameStatus.inProgress) return;
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      ref.invalidate(gamesByRoundProvider(widget.game.roundId));
      ref.invalidate(gameScoreEventsProvider(widget.game.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameContextCard(game: game),
        const SizedBox(height: 16),
        switch (game.status) {
          GameStatus.scheduled => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppInfoCard(
                  title: 'Partida agendada',
                  icon: Icons.event,
                  children: [
                    AppInfoRow(label: 'Status', value: game.status.label),
                    AppInfoRow(
                      label: 'Data',
                      value: formatDateTime(game.scheduledAt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Abrir partida'),
                  onPressed: () => _confirmOpen(game),
                ),
                // A conferência de atletas só é acessível quando a partida
                // estiver aberta (OPEN) — issue #490.
              ],
            ),
          GameStatus.open => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppInfoCard(
                  title: 'Abertura da partida',
                  icon: Icons.login,
                  children: [
                    AppInfoRow(
                      label: 'Status',
                      value: '${game.status.label} — a mesa confere o check-in '
                          'dos atletas antes de iniciar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Conferência de atletas'),
                  onPressed: () => context.push('/checkin'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar partida'),
                  onPressed: () => _confirmStart(game),
                ),
              ],
            ),
          GameStatus.inProgress => _liveControls(game),
          GameStatus.conference => _conferencePanel(game),
          // Jogos encerrados/cancelados deixavam a área em branco (#12).
          GameStatus.finished => _finishedSummary(game),
          GameStatus.cancelled => _cancelledSummary(game),
        },
      ],
    );
  }

  Widget _liveControls(Game game) {
    final theme = Theme.of(context);
    final homeLabel = game.homeTeamName ?? 'Casa';
    final awayLabel = game.awayTeamName ?? 'Fora';
    final isBusy = _busyTeamId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _scoreTeam(
                        label: homeLabel,
                        // Semantics "Time da casa" em vez de "Casa" (#13).
                        semanticsLabel: 'Time da casa: $homeLabel',
                        score: game.homeScore ?? 0,
                        // Desabilita "+1" quando o id do time é nulo (#13).
                        enabled: !isBusy && game.homeTeamId != null,
                        onAdd: () => _addPoint(game, game.homeTeamId!),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Semantics(
                        label:
                            'Placar: $homeLabel ${game.homeScore ?? 0} x '
                            '${game.awayScore ?? 0} $awayLabel',
                        child: Text(
                          '${game.homeScore ?? 0} x ${game.awayScore ?? 0}',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _scoreTeam(
                        label: awayLabel,
                        semanticsLabel: 'Time visitante: $awayLabel',
                        score: game.awayScore ?? 0,
                        enabled: !isBusy && game.awayTeamId != null,
                        onAdd: () => _addPoint(game, game.awayTeamId!),
                      ),
                    ),
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
        ),
        const SizedBox(height: 16),
        _ScoreTimelineCard(game: game),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.assignment_turned_in),
          label: const Text('Colocar em conferência'),
          onPressed: () => _confirmConference(game),
        ),
      ],
    );
  }

  Widget _scoreTeam({
    required String label,
    required String semanticsLabel,
    required int score,
    required bool enabled,
    required VoidCallback onAdd,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
          Text('$score', style: theme.textTheme.titleLarge),
          IconButton(
            tooltip: '+1 $label',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: enabled ? onAdd : null,
          ),
        ],
      ),
    );
  }

  Future<void> _addPoint(Game game, String teamId) async {
    if (_busyTeamId != null) return; // anti-duplo-toque (#8)
    setState(() => _busyTeamId = teamId);
    try {
      await ref.read(gameApiProvider).addScoreEvent(game.id, teamId);
      // Invalida também os eventos de pontuação — timeline atualiza (#1).
      ref.invalidate(gamesByRoundProvider(game.roundId));
      ref.invalidate(gameScoreEventsProvider(game.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ponto registrado'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      if (mounted) _showSnack('Não foi possível registrar o ponto');
    } finally {
      if (mounted) setState(() => _busyTeamId = null);
    }
  }

  Future<void> _correctScore(Game game) async {
    final home = TextEditingController(text: (game.homeScore ?? 0).toString());
    final away = TextEditingController(text: (game.awayScore ?? 0).toString());
    final formKey = GlobalKey<FormState>();

    // Dialog com validação no campo (issue #425#9/#22): só fecha com valor
    // inteiro ≥ 0 — nada de converter inválido silenciosamente para 0.
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Corrigir placar'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: home,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Time da casa'),
                validator: _nonNegativeScoreValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: away,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Time de fora'),
                validator: _nonNegativeScoreValidator,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (saved == true) {
      try {
        await ref.read(gameApiProvider).correctScore(
              game.id,
              homeScore: int.parse(home.text),
              awayScore: int.parse(away.text),
            );
        ref.invalidate(gamesByRoundProvider(game.roundId));
        ref.invalidate(gameScoreEventsProvider(game.id));
        if (mounted) _showSnack('Placar atualizado', isError: false);
      } catch (_) {
        if (mounted) _showSnack('Não foi possível corrigir o placar');
      }
    }
    home.dispose();
    away.dispose();
  }

  Future<void> _confirmOpen(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abrir partida'),
        content: Text(
          'Abrir "${game.homeTeamName ?? 'Casa'} x '
          '${game.awayTeamName ?? 'Fora'}" agora para a conferência dos '
          'atletas?\n\n${formatDateTime(game.scheduledAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(gameApiProvider)
          .updateStatus(game.id, GameStatus.open);
      ref.invalidate(gamesByRoundProvider(game.roundId));
      ref.invalidate(gameScoreEventsProvider(game.id));
      if (mounted) _showSnack('Partida aberta', isError: false);
    } catch (_) {
      if (mounted) _showSnack('Não foi possível abrir a partida');
    }
  }

  Future<void> _confirmStart(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Iniciar partida'),
        content: Text(
          'Iniciar "${game.homeTeamName ?? 'Casa'} x '
          '${game.awayTeamName ?? 'Fora'}" agora?\n\n'
          '${formatDateTime(game.scheduledAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(gameApiProvider)
          .updateStatus(game.id, GameStatus.inProgress);
      ref.invalidate(gamesByRoundProvider(game.roundId));
      ref.invalidate(gameScoreEventsProvider(game.id));
    } catch (_) {
      if (mounted) _showSnack('Não foi possível iniciar a partida');
    }
  }

  Future<void> _confirmConference(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Colocar em conferência'),
        content: const Text(
          'Colocar esta partida em conferência para a arbitragem confirmar '
          'o placar antes de finalizar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Conferir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(gameApiProvider)
          .updateStatus(game.id, GameStatus.conference);
      ref.invalidate(gamesByRoundProvider(game.roundId));
      ref.invalidate(gameScoreEventsProvider(game.id));
      if (mounted) _showSnack('Partida em conferência', isError: false);
    } catch (_) {
      if (mounted) _showSnack('Não foi possível colocar em conferência');
    }
  }

  Future<void> _confirmFinish(Game game) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar partida'),
        content: const Text('Tem certeza que deseja finalizar esta partida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(gameApiProvider)
          .updateStatus(game.id, GameStatus.finished);
      ref.invalidate(gamesByRoundProvider(game.roundId));
      ref.invalidate(gameScoreEventsProvider(game.id));
      if (mounted) _showSnack('Partida finalizada', isError: false);
    } catch (_) {
      if (mounted) _showSnack('Não foi possível finalizar a partida');
    }
  }

  /// Resumo do jogo encerrado: status + placar final (issue #425#12).
  Widget _finishedSummary(Game game) {
    final homeLabel = game.homeTeamName ?? 'Casa';
    final awayLabel = game.awayTeamName ?? 'Fora';
    return AppInfoCard(
      title: 'Resultado final',
      icon: Icons.flag_outlined,
      children: [
        AppInfoRow(label: 'Status', value: game.status.label),
        AppInfoRow(
          label: 'Placar',
          value: '$homeLabel ${game.homeScore ?? 0} x '
              '${game.awayScore ?? 0} $awayLabel',
        ),
      ],
    );
  }

  /// Card informativo de partida cancelada (issue #425#12).
  Widget _cancelledSummary(Game game) {
    return AppInfoCard(
      title: 'Partida cancelada',
      icon: Icons.event_busy_outlined,
      children: [
        AppInfoRow(label: 'Status', value: game.status.label),
      ],
    );
  }

  /// Painel de conferência da arbitragem (issue #488): etapa intermediária
  /// entre IN_PROGRESS e FINISHED para confirmar/corrigir antes de finalizar.
  /// Sentido único: CONFERENCE só sai para FINISHED.
  Widget _conferencePanel(Game game) {
    final homeLabel = game.homeTeamName ?? 'Casa';
    final awayLabel = game.awayTeamName ?? 'Fora';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInfoCard(
          title: 'Conferência da arbitragem',
          icon: Icons.assignment_turned_in,
          children: [
            AppInfoRow(label: 'Status', value: game.status.label),
            AppInfoRow(
              label: 'Placar',
              value: '$homeLabel ${game.homeScore ?? 0} x '
                  '${game.awayScore ?? 0} $awayLabel',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ScoreTimelineCard(game: game),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text('Finalizar partida'),
          onPressed: () => _confirmFinish(game),
        ),
      ],
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }
}

/// Valida um placar: inteiro ≥ 0 (issue #425#9/#22).
String? _nonNegativeScoreValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Informe um valor';
  final parsed = int.tryParse(text);
  if (parsed == null || parsed < 0) return 'Use um número inteiro ≥ 0';
  return null;
}

/// Card de timeline de pontos de uma partida (consome os score events).
class _ScoreTimelineCard extends ConsumerWidget {
  const _ScoreTimelineCard({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(gameScoreEventsProvider(game.id));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sequência de pontos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            events.when(
              loading: () => const AppLoading(message: 'Carregando pontos...'),
              error: (e, s) => Text(
                'Não foi possível carregar os pontos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                ),
              ),
              data: (items) => items.isEmpty
                  ? Text(
                      'Nenhum ponto registrado ainda',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  : ScoreTimeline(game: game, events: items),
            ),
          ],
        ),
      ),
    );
  }
}