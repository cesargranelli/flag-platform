import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';

import '../widgets/app_screen.dart';

/// Paleta LA Chargers aplicada aos elementos visuais do projeto.
abstract final class ChargersPalette {
  static const Color powderBlue = Color(0xFF0080FC);
  static const Color aztecBlue = Color(0xFF002244);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gold = Color(0xFFFFC20E);
}

/// Tela de teste visual da marca (issue #427, item 4).
///
/// Demonstra todos os elementos visuais do Admin Web com a paleta LA
/// Chargers (Azul Powder, Aztec Blue, Branco e Dourado), organizados por
/// seções com título. Serve para o usuário validar a identidade visual.
class VisualTestScreen extends StatelessWidget {
  const VisualTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Teste visual — LA Chargers',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppLayout.content(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                'Cores',
                child: _colorsSection(),
              ),
              _Section(
                'Tipografia',
                child: _typographySection(context),
              ),
              _Section(
                'Botões',
                child: _buttonsSection(),
              ),
              _Section(
                'Inputs',
                child: _inputsSection(),
              ),
              _Section(
                'Cards',
                child: _cardsSection(),
              ),
              _Section(
                'Chips e badges',
                child: _chipsSection(),
              ),
              _Section(
                'Tabela',
                child: _tableSection(),
              ),
              _Section(
                'Placar',
                child: _scoreboardSection(),
              ),
              _Section(
                'Timeline de pontuação',
                child: _timelineSection(),
              ),
              _Section(
                'Seletores',
                child: _selectorsSection(),
              ),
              _Section(
                'Avatares',
                child: _avatarsSection(),
              ),
              _Section(
                'Alertas',
                child: _alertsSection(context),
              ),
              _Section(
                'Progresso',
                child: _progressSection(),
              ),
              _Section(
                'Listas com divisores',
                child: _dividersSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ //
  // Cores
  // ------------------------------------------------------------------ //
  Widget _colorsSection() {
    const colors = [
      (ChargersPalette.powderBlue, 'Azul Powder', '#0080FC'),
      (ChargersPalette.aztecBlue, 'Aztec Blue', '#002244'),
      (ChargersPalette.white, 'Branco', '#FFFFFF'),
      (ChargersPalette.gold, 'Dourado', '#FFC20E'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (color, name, hex) in colors)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(hex, style: const TextStyle(fontSize: 12)),
            ],
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Tipografia
  // ------------------------------------------------------------------ //
  Widget _typographySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Headline 1 — destaque da marca',
          style: AppTextStyles.headline1.copyWith(color: ChargersPalette.aztecBlue),
        ),
        const SizedBox(height: 12),
        Text(
          'Título de tela (headlineMedium)',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: ChargersPalette.powderBlue),
        ),
        const SizedBox(height: 8),
        Text(
          'Subtítulo — texto de apoio ao título',
          style: AppTextStyles.subtitle.copyWith(color: ChargersPalette.aztecBlue),
        ),
        const SizedBox(height: 8),
        Text(
          'Corpo de texto: parágrafo padrão do design system, usado nas '
          'listagens, cards e descrições de tela.',
          style: AppTextStyles.paragraph,
        ),
        const SizedBox(height: 8),
        const Text(
          'Caption/metadados — pequeno, secundário.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Botões
  // ------------------------------------------------------------------ //
  Widget _buttonsSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: ChargersPalette.powderBlue,
          ),
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Novo'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: ChargersPalette.powderBlue.withValues(alpha: 0.15),
            foregroundColor: ChargersPalette.aztecBlue,
          ),
          onPressed: () {},
          child: const Text('Tonal'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ChargersPalette.powderBlue,
            side: const BorderSide(color: ChargersPalette.powderBlue),
          ),
          onPressed: () {},
          child: const Text('Outlined'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: ChargersPalette.powderBlue,
          ),
          onPressed: () {},
          child: const Text('Text button'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ChargersPalette.gold,
            foregroundColor: ChargersPalette.aztecBlue,
          ),
          onPressed: () {},
          child: const Text('Dourado'),
        ),
        const FilledButton(onPressed: null, child: Text('Desabilitado')),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Inputs
  // ------------------------------------------------------------------ //
  Widget _inputsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'TextField',
            hintText: 'Campo simples',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'TextFormField',
            helperText: 'Com rótulo e helper',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: 'Clube',
          decoration: const InputDecoration(
            labelText: 'DropdownButtonFormField',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Clube', child: Text('Clube')),
            DropdownMenuItem(value: 'Liga', child: Text('Liga')),
            DropdownMenuItem(value: 'Federação', child: Text('Federação')),
          ],
          onChanged: (_) {},
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Cards
  // ------------------------------------------------------------------ //
  Widget _cardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Card básico',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: ChargersPalette.powderBlue.withValues(alpha: 0.15),
                  child: const Text(
                    'CA',
                    style: TextStyle(
                      color: ChargersPalette.powderBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Card com avatar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Subtítulo do card',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card de jogo',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(child: Text('Chargers', style: TextStyle(fontWeight: FontWeight.w600))),
                    Text('21', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('x', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    Text('14', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(
                        'Raiders',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Chips / badges
  // ------------------------------------------------------------------ //
  Widget _chipsSection() {
    Widget chip(String label, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: color)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Agendado', AppColors.textSecondary),
        chip('Ao vivo', AppColors.success),
        chip('Encerrado', AppColors.danger),
        chip('Cancelado', AppColors.disabled),
        chip('#17 · WR', ChargersPalette.powderBlue),
        chip('QB', ChargersPalette.gold),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: ChargersPalette.aztecBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'CAPITÃO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ChargersPalette.white,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Tabela (classificação)
  // ------------------------------------------------------------------ //
  Widget _tableSection() {
    const rows = [
      ('1', 'Los Angeles Chargers', 3, 0, 96),
      ('2', 'Kansas City Chiefs', 2, 1, 78),
      ('3', 'Las Vegas Raiders', 1, 2, 54),
      ('4', 'Denver Broncos', 0, 3, 31),
    ];
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: AppColors.grayFill, width: 1),
        bottom: const BorderSide(color: AppColors.grayFill),
      ),
      columnWidths: const {
        0: FixedColumnWidth(36),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(48),
        3: FixedColumnWidth(48),
        4: FixedColumnWidth(56),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Pos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('V', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('D', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Pts', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            ),
          ],
        ),
        for (final (pos, team, wins, losses, points) in rows)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  pos,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ChargersPalette.powderBlue,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(team, style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('$wins', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('$losses', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('$points', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Placar
  // ------------------------------------------------------------------ //
  Widget _scoreboardSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChargersPalette.aztecBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Q4 · 02:12',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: ChargersPalette.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHARGERS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: ChargersPalette.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Los Angeles',
                      style: TextStyle(
                        fontSize: 11,
                        color: ChargersPalette.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 48,
                color: ChargersPalette.gold,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '21',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: ChargersPalette.gold,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  '14',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: ChargersPalette.gold,
                  ),
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RAIDERS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: ChargersPalette.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Las Vegas',
                      style: TextStyle(
                        fontSize: 11,
                        color: ChargersPalette.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 0.78,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
            backgroundColor: ChargersPalette.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation(ChargersPalette.gold),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ //
  // Timeline (ScoreTimeline do core)
  // ------------------------------------------------------------------ //
  Widget _timelineSection() {
    final now = DateTime.now();
    final game = Game(
      id: 'visual-test-game',
      roundId: 'visual-test-round',
      competitionId: 'visual-test',
      homeTeamId: 'home',
      awayTeamId: 'away',
      homeTeamName: 'Chargers',
      awayTeamName: 'Raiders',
      scheduledAt: now.subtract(const Duration(minutes: 60)),
      status: GameStatus.inProgress,
      homeScore: 21,
      awayScore: 14,
    );
    final events = [
      ScoreEvent(
        id: 'e1',
        gameId: game.id,
        teamId: 'home',
        createdAt: now.subtract(const Duration(minutes: 48)),
      ),
      ScoreEvent(
        id: 'e2',
        gameId: game.id,
        teamId: 'away',
        createdAt: now.subtract(const Duration(minutes: 31)),
      ),
      ScoreEvent(
        id: 'e3',
        gameId: game.id,
        teamId: 'home',
        createdAt: now.subtract(const Duration(minutes: 9)),
      ),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ScoreTimeline(game: game, events: events),
      ),
    );
  }

  // ------------------------------------------------------------------ //
  // Seletores
  // ------------------------------------------------------------------ //
  Widget _selectorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Switch'),
          value: true,
          activeThumbColor: ChargersPalette.powderBlue,
          onChanged: (_) {},
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Checkbox'),
          value: true,
          activeColor: ChargersPalette.powderBlue,
          onChanged: (_) {},
        ),
        RadioGroup<bool>(
          groupValue: true,
          onChanged: (_) {},
          child: RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Radio'),
            value: true,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Avatares
  // ------------------------------------------------------------------ //
  Widget _avatarsSection() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: ChargersPalette.powderBlue.withValues(alpha: 0.15),
          child: const Text(
            'JT',
            style: TextStyle(
              color: ChargersPalette.powderBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: ChargersPalette.gold,
          child: const Text(
            'HC',
            style: TextStyle(
              color: ChargersPalette.aztecBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ChargersPalette.powderBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: ChargersPalette.powderBlue,
            size: 28,
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ChargersPalette.aztecBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_outlined, color: ChargersPalette.gold, size: 28),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Alertas
  // ------------------------------------------------------------------ //
  Widget _alertsSection(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sucesso: organização salva!')),
          ),
          icon: const Icon(Icons.check),
          label: const Text('SnackBar sucesso'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: não foi possível salvar.')),
          ),
          icon: const Icon(Icons.error_outline),
          label: const Text('SnackBar erro'),
        ),
        OutlinedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Alerta'),
              content: const Text('Este é um diálogo de exemplo.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
          child: const Text('Dialog'),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Progresso
  // ------------------------------------------------------------------ //
  Widget _progressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: 0.6,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: ChargersPalette.powderBlue.withValues(alpha: 0.12),
          valueColor: const AlwaysStoppedAnimation(ChargersPalette.powderBlue),
        ),
        const SizedBox(height: 12),
        const LinearProgressIndicator(minHeight: 6),
        const SizedBox(height: 12),
        const Row(
          children: [
            CircularProgressIndicator(
              value: 0.7,
              color: ChargersPalette.powderBlue,
            ),
            SizedBox(width: 16),
            CircularProgressIndicator(color: ChargersPalette.gold),
            SizedBox(width: 16),
            CircularProgressIndicator(),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ //
  // Divisores / listas
  // ------------------------------------------------------------------ //
  Widget _dividersSection() {
    return const Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.sports_football, color: ChargersPalette.powderBlue),
          title: Text('Los Angeles Chargers'),
          subtitle: Text('AFC Oeste · 3V 0D'),
        ),
        Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.sports_football, color: ChargersPalette.powderBlue),
          title: Text('Kansas City Chiefs'),
          subtitle: Text('AFC Oeste · 2V 1D'),
        ),
        Divider(height: 1),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.sports_football, color: ChargersPalette.powderBlue),
          title: Text('Las Vegas Raiders'),
          subtitle: Text('AFC Oeste · 1V 2D'),
        ),
      ],
    );
  }
}

/// Seção da tela de teste visual: título + conteúdo em card.
class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ChargersPalette.aztecBlue,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}