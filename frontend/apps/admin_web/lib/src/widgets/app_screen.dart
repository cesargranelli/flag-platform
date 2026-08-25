import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Scaffold padrão do Admin Web com navbar global.
///
/// Toda tela autenticada usa este wrapper: AppBar com título, leading
/// opcional e actions da tela, seguidos SEMPRE do chip de usuário (avatar
/// com iniciais + nome), que abre o menu com a ação "Sair" (com confirmação).
/// Telas pré-autenticação (login, signup, recuperação de senha) não o utilizam.
class AppScreen extends ConsumerWidget {
  const AppScreen({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.state.user?.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: leading,
        actions: [
          ...?actions,
          // Issue #284: nome do usuário fora do padrão (cinza sobre o AppBar
          // primary). O par nome + botão sair virou um único chip de conta,
          // alinhado ao tema do AppBar (fundo primary/texto branco).
          if (auth.state.authenticated)
            _UserChip(
              name: userName,
              onLogout: () => _confirmLogout(context, ref),
            ),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final logout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (logout == true) {
      // O GoRouter observa o AuthController e redireciona para /login.
      ref.read(authControllerProvider.notifier).logout();
    }
  }
}

/// Chip de usuário da navbar global (issue #284).
///
/// Composição: avatar circular de 32px (fundo `surface`, iniciais em
/// `primary` — ou ícone persona quando o nome está vazio/null) + nome em
/// branco, 13px w600, com ellipsis. O chip tem um scrim escuro sutil
/// (preto @25%): sobre o AppBar `primary` (#FD6B22), nenhum tom claro atinge
/// AA 4.5:1 — o scrim eleva o contraste do texto branco para ~4.8:1 e ainda
/// delimita visualmente o alvo de toque (raio `radius.chip` = 10).
/// O toque abre um [PopupMenuButton] com "Sair"; a confirmação existente é
/// preservada via [AppScreen._confirmLogout].
class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.onLogout});

  final String? name;
  final VoidCallback onLogout;

  /// Alvo de toque mínimo do design system (tokens.md).
  static const double _tapTargetHeight = 48;

  static final RegExp _wordSeparator = RegExp(r'[\s-]+');

  String get _displayName => (name ?? '').trim();

  /// Primeiras letras dos dois primeiros nomes ("Maria Silva" -> "MS").
  String get _initials {
    final parts =
        _displayName.split(_wordSeparator).where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final hasName = displayName.isNotEmpty;
    // Responsivo: abaixo de 480px de viewport o nome colapsa e resta o
    // avatar (com menu). MediaQuery (largura da janela) em vez de
    // LayoutBuilder: dentro de `actions`, as constraints dependem do
    // comprimento do título centralizado — o mesmo usuário mudaria de
    // formato entre telas; a largura da janela é determinística.
    final showName = hasName && MediaQuery.sizeOf(context).width >= 480;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: PopupMenuButton<String>(
        tooltip: 'Opções da conta',
        onSelected: (value) {
          if (value == 'logout') onLogout();
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout_outlined, size: 20),
                SizedBox(width: 8),
                Text('Sair'),
              ],
            ),
          ),
        ],
        // SizedBox de 48px garante o alvo de toque na altura do chip.
        child: SizedBox(
          height: _tapTargetHeight,
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surface,
                    child: hasName
                        ? Text(
                            _initials,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                  ),
                  if (showName) ...[
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
