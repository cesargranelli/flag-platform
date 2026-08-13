import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Tela de detalhe do campeonato (placeholder da issue #28).
///
/// Por enquanto apenas exibe o nome do campeonato recebido na navegação;
/// quando o endpoint de detalhe for integrado, a tela carregará os dados
/// completos via `competitionId`.
class CompetitionDetailScreen extends StatelessWidget {
  final String competitionId;
  final String competitionName;

  const CompetitionDetailScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  Widget build(BuildContext context) {
    final title = competitionName.isEmpty ? competitionId : competitionName;

    return Scaffold(
      appBar: AppBar(title: const Text('Campeonato')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Detalhes em breve',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
