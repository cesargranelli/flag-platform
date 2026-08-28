import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../widgets/match_score_card.dart';

/// Aba "Ao vivo" (issue #391): timeline de livescore com dados FAKE do própio
/// app (sem backend), para visualizar como ficará o livescore no MVP.
///
/// Mostra "Ao vivo agora" (jogos `inProgress`, com o badge AO VIVO do
/// `MatchStatusBadge`) e "Recentemente" (jogos encerrados). Os cards são
/// apenas de leitura (sem `onTap`) para não depender de backend no demo.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(fakeLiveGamesProvider);

    final live = games.where((g) => g.status == GameStatus.inProgress).toList();
    final recent = games.where((g) => g.status == GameStatus.finished).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ao vivo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          if (live.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Nenhum jogo ao vivo no momento.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...live.map(
              (game) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LiveTimelineItem(game: game),
              ),
            ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionTitle('Recentemente'),
            const SizedBox(height: 8),
            ...recent.map(
              (game) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchScoreCard(
                  game: game,
                  showMeta: true,
                  showVenue: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Item da timeline ao vivo: linha vertical + "ponto pulsante" + card.
class _LiveTimelineItem extends StatelessWidget {
  final Game game;

  const _LiveTimelineItem({required this.game});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trilho vertical com o "ponto" do livescore.
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const ShiftingLiveDot(),
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.grayFill,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: MatchScoreCard(
              game: game,
              showMeta: true,
              showVenue: true,
              showRound: true,
            ),
          ),
        ],
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

/// Ponto "ao vivo" com animação de pulso (switch de opacidade).
class ShiftingLiveDot extends StatefulWidget {
  const ShiftingLiveDot({super.key});

  @override
  State<ShiftingLiveDot> createState() => _ShiftingLiveDotState();
}

class _ShiftingLiveDotState extends State<ShiftingLiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.25,
      upperBound: 1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
