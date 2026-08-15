import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tela temporária para rotas de autenticação ainda não implementadas.
class AuthPlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const AuthPlaceholderScreen({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          leading: BackButton(onPressed: () => context.go('/login')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.darkTextMuted)),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Voltar ao login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
