import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela de login do Admin Web (layout split: formulário à esquerda, arte à direita).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _keepConnected = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            keepConnected: _keepConnected,
          );
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.loginConnectionError);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            return Row(
              children: [
                Expanded(
                  flex: wide ? 5 : 1,
                  child: _buildForm(context, wide),
                ),
                if (wide)
                  Expanded(
                    flex: 5,
                    child: _buildArt(context),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool wide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 420 : 400),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports, color: AppColors.darkBrand),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.loginTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              const Text(
                'Acesse sua conta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.loginSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.darkTextMuted, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: AppStrings.loginEmail,
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.loginRequiredEmail;
                  }
                  if (!value.contains('@')) {
                    return AppStrings.loginInvalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: AppStrings.loginPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? AppStrings.loginRequiredPassword
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _keepConnected,
                        onChanged: (value) =>
                            setState(() => _keepConnected = value ?? false),
                      ),
                      const Text(
                        'Manter conectado',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Esqueci a senha'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.loginSubmit),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Não tem conta?',
                    style: TextStyle(color: AppColors.darkTextMuted),
                  ),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Criar conta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArt(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F2924), AppColors.darkBackground],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Icon(
              Icons.sports_soccer,
              size: 320,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: AppColors.darkBrand,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'O melhor lugar para acompanhar um campeonato de flag',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Organize, acompanhe e viva o jogo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.darkTextMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
