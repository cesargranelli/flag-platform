import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/match_score_card.dart';

/// Aba "Ao vivo" (issue #391): lista de jogos ao vivo consumindo a API real.
///
/// Mostra "Ao vivo agora" (jogos `inProgress`) e "Recentemente" (jogos
/// encerrados). Cada card tem um botão "Lance a Lance" para ver a timeline.
/// Exibe estados de carregamento e erro com feedback adequado ao usuário.
class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGames = ref.watch(liveGamesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ao vivo')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(liveGamesProvider);
          await ref.read(liveGamesProvider.future);
        },
        child: asyncGames.when(
          loading: () =>
              const AppLoading(message: 'Carregando jogos ao vivo...'),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 120),
              AppErrorState(
                message: 'Não foi possível carregar os jogos ao vivo',
              ),
            ],
          ),
          data: (allGames) {
            final live = allGames
                .where((lg) => lg.game.status == GameStatus.inProgress)
                .toList();
            final recent = allGames
                .where((lg) => lg.game.status == GameStatus.finished)
                .toList();

            return ListView(
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
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ...live.map(
                    (lg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MatchScoreCard(
                        game: lg.game,
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
                          'Confira os resultados na aba Campeonato',
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
            );
          },
        ),
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
    return Semantics(
      label: 'Indicador de jogo ao vivo',
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
