import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Tela "Sobre" do Public App (issue #389).
///
/// Apresenta o app, a versão e um breve "como funciona" para o torcedor que
/// chega sem login.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Versão exibida — mantida em sincronia com `pubspec.yaml` (`0.1.0+1`).
  static const _version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: AppLayout.content(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            const Icon(
              Icons.sports_football,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Flag Public App',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Versão $_version',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Como funciona',
              style: AppTextStyles.headline1.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            const _InfoItem(
              icon: Icons.tips_and_updates_outlined,
              title: 'Acompanhe um campeonato',
              description:
                  'Escolha um campeonato na aba Início. Ele passa a ser o seu '
                  '"campeonato em foco", lembrado entre visitas.',
            ),
            const SizedBox(height: 12),
            const _InfoItem(
              icon: Icons.calendar_month_outlined,
              title: 'Jogos, resultados e classificação',
              description:
                  'Na aba Campeonato você acompanha o calendário de jogos, os '
                  'resultados e a tabela de classificação do campeonato em foco.',
            ),
            const SizedBox(height: 12),
            const _InfoItem(
              icon: Icons.swap_horiz,
              title: 'Trocar de campeonato',
              description:
                  'Use "Trocar" no topo do campeonato para voltar à lista e '
                  'escolher outro.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Item da seção "Como funciona": ícone + título + descrição.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
