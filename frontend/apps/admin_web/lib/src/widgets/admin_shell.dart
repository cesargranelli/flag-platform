import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Shell do Admin Web (issue #427), simplificado na issue #433.
///
/// Header global fixo (marca + chip de usuário) sobre o conteúdo da branch
/// ativa ([StatefulNavigationShell]). Sem menu no header: a navegação entre
/// módulos agora é feita pelos cards da home e a marca leva de volta ao
/// início (`context.go('/')`). O estado de cada módulo é preservado pelo
/// IndexedStack do GoRouter.
class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          _Header(onLogout: () => _confirmLogout(context, ref)),
          Expanded(child: navigationShell),
        ],
      ),
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

/// Header global: marca à esquerda + chip de usuário à direita.
///
/// Composição única para todas as larguras (issue #433): sem hambúrguer e
/// sem menu para abrir em telas estreitas.
class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _Brand(onTap: () => context.go('/')),
            const Spacer(),
            AdminUserChip(onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

/// Marca: escudo + nome do produto; toque volta ao início.
class _Brand extends StatelessWidget {
  const _Brand({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Admin Web',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de usuário da navbar global (issue #284, movido para o shell na #427).
///
/// Composição: avatar circular de 32px (fundo `surface`, iniciais em
/// `primary` — ou ícone persona quando o nome está vazio/null) + nome em
/// branco, 13px w600, com ellipsis. O chip tem um scrim escuro sutil
/// (preto @25%): sobre o header `primary` (azul royal #083879, branco
/// ~7.7:1), o scrim reforça ainda mais o contraste do texto branco e delimita
/// visualmente o alvo de toque (raio `radius.chip` = 10).
class AdminUserChip extends ConsumerWidget {
  const AdminUserChip({super.key, required this.onLogout});

  final VoidCallback onLogout;

  /// Alvo de toque mínimo do design system (tokens.md).
  static const double _tapTargetHeight = 48;

  static final RegExp _wordSeparator = RegExp(r'[\s-]+');

  String _displayName(String? name) => (name ?? '').trim();

  /// Primeiras letras dos dois primeiros nomes ("Maria Silva" -> "MS").
  String _initials(String? name) {
    final parts = _displayName(name)
        .split(_wordSeparator)
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).state.user?.name;
    final displayName = _displayName(name);
    final hasName = displayName.isNotEmpty;
    // Responsivo: abaixo de 480px de viewport o nome colapsa e resta o
    // avatar (com menu).
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
                            _initials(name),
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