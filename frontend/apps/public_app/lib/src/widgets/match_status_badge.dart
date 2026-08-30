import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Badge de status da partida, no padrão live score.
///
/// - Em andamento → "AO VIVO" em vermelho ([AppColors.danger]) com ponto
///   pulsante sutil;
/// - Encerrado → "Finalizado" em preenchimento neutro;
/// - Cancelado → "Cancelado" em preenchimento neutro;
/// - Agendado → data/hora da partida ("Hoje · HH:mm" quando for no mesmo dia).
class MatchStatusBadge extends StatelessWidget {
  final GameStatus status;
  final DateTime? scheduledAt;

  const MatchStatusBadge({super.key, required this.status, this.scheduledAt});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      GameStatus.inProgress => _Pill(
        background: AppColors.danger,
        foreground: Colors.white,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [_LiveDot(), SizedBox(width: 6), Text('AO VIVO')],
        ),
      ),
      // Abertura e conferência: estágios intermediários não vistos como
      // "ao vivo" pelo público (issue #488) — pill neutra.
      GameStatus.open => const _Pill(
        background: AppColors.grayFill,
        foreground: AppColors.textPrimary,
        child: Text('Abertura'),
      ),
      GameStatus.conference => const _Pill(
        background: AppColors.grayFill,
        foreground: AppColors.textPrimary,
        child: Text('Conferência'),
      ),
      GameStatus.finished => const _Pill(
        background: AppColors.grayFill,
        foreground: AppColors.textPrimary,
        child: Text('Finalizado'),
      ),
      GameStatus.cancelled => const _Pill(
        background: AppColors.grayFill,
        foreground: AppColors.textPrimary,
        child: Text('Cancelado'),
      ),
      GameStatus.scheduled => _Pill(
        background: AppColors.grayFill,
        foreground: AppColors.textPrimary,
        child: Text(_scheduleLabel()),
      ),
    };
  }

  /// Rótulo de agendados: só a hora quando é hoje; senão data + hora.
  String _scheduleLabel() {
    final at = scheduledAt;
    if (at == null) return 'Agendado';
    final now = DateTime.now();
    final isToday =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return isToday
        ? DateFormat('HH:mm').format(at)
        : DateFormat('dd/MM · HH:mm').format(at);
  }
}

/// Pílula base do badge (raio `radius.status` dos tokens).
class _Pill extends StatelessWidget {
  final Color background;
  final Color foreground;
  final Widget child;

  const _Pill({
    required this.background,
    required this.foreground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: foreground,
        ),
        child: child,
      ),
    );
  }
}

/// Ponto pulsante do "AO VIVO" (animação sutil, apenas decorativa).
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      opacity: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: ExcludeSemantics(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
