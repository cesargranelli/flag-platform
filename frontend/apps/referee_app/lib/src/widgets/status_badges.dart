import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';

/// Chip de status de jogo (Agendado / Abertura / Ao vivo / Conferência /
/// Encerrado / Cancelado).
///
/// Usa `GameStatus.label` do domain (pt-BR) e cor semântica por estado
/// (padrão admin_web `_statusChip`), com `Semantics` de apoio (issue #425#4).
class GameStatusChip extends StatelessWidget {
  const GameStatusChip({super.key, required this.status});

  final GameStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GameStatus.scheduled => ('Agendado', AppColors.textSecondary),
      GameStatus.open => ('Abertura', AppColors.warning),
      GameStatus.inProgress => ('Ao vivo', AppColors.success),
      GameStatus.conference => ('Conferência', AppColors.warning),
      GameStatus.finished => ('Encerrado', AppColors.danger),
      GameStatus.cancelled => ('Cancelado', AppColors.disabled),
    };
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Badge de status do atleta no check-in (issue #425#6).
///
/// Dá representação visual a todos os estados — inclusive `validated`, que
/// antes caía no caso vazio — com ícone + cor semântica e `Semantics`.
class CheckInStatusBadge extends StatelessWidget {
  const CheckInStatusBadge({super.key, required this.status});

  final CheckInStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      CheckInStatus.validated => (
        'VALIDADO',
        AppColors.success,
        Icons.check_circle,
      ),
      CheckInStatus.present => (
        'PRESENTE',
        AppColors.success,
        Icons.check_circle_outline,
      ),
      CheckInStatus.noShow => (
        'FALTOU',
        AppColors.danger,
        Icons.cancel_outlined,
      ),
      CheckInStatus.notRegistered => (
        'FORA DO ROSTER',
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      CheckInStatus.pending => (
        'PENDENTE',
        AppColors.textSecondary,
        Icons.schedule,
      ),
    };
    // Conteúdo (ícone + texto) escuro quando a cor semântica é o amarelo
    // `warning` (#FACC15): o tom é claro demais para texto/ícone na própria
    // cor sobre o fundo @12% (issue #431 — contraste).
    final contentColor =
        color == AppColors.warning ? AppColors.textPrimary : color;
    return Semantics(
      label: 'Status do atleta: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: contentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: contentColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}