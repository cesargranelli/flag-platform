import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'kickster_badge.dart';

/// Card de jogo com placar no estilo Live Match do kit Kickster (issue
/// #436).
///
/// Confronto (Time A × Time B), placar destacado no centro e badge de status
/// semântico (`GameStatus.label`). Raio 12, fundo `surface`, elevação 1.
/// Toque opcional via `InkWell` padrão do tema (#300).
class KicksterScoreCard extends StatelessWidget {
  const KicksterScoreCard({
    super.key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    this.onTap,
  });

  final String homeTeamName;
  final String awayTeamName;
  final int homeScore;
  final int awayScore;
  final GameStatus status;
  final VoidCallback? onTap;

  /// Cor semântica do status: ao vivo = success; encerrado = danger;
  /// agendado = textSecondary; cancelado = disabled; abertura/conferência =
  /// tom neutro (não são "ao vivo").
  Color get _statusColor => switch (status) {
        GameStatus.inProgress => AppColors.success,
        GameStatus.finished => AppColors.danger,
        GameStatus.scheduled => AppColors.textSecondary,
        GameStatus.open => AppColors.textSecondary,
        GameStatus.conference => AppColors.textSecondary,
        GameStatus.cancelled => AppColors.disabled,
      };

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  homeTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: KicksterBadge(label: status.label, color: _statusColor),
              ),
              Expanded(
                child: Text(
                  awayTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$homeScore', style: _scoreStyle(context)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '×',
                  style: _scoreStyle(context).copyWith(
                    fontSize: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text('$awayScore', style: _scoreStyle(context)),
            ],
          ),
        ],
      ),
    );

    return Card(
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }

  /// Placar destacado em escala de título do tema (headlineSmall — 32/40
  /// w700, "headline1-ish" em contexto de card).
  TextStyle _scoreStyle(BuildContext context) {
    return (Theme.of(context).textTheme.headlineSmall ??
            const TextStyle(fontSize: 32, fontWeight: FontWeight.w700))
        .copyWith(color: AppColors.textPrimary);
  }
}