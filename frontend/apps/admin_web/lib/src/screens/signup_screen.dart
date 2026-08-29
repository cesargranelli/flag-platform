import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela de cadastro do organizador no visual do kit Kickster (issue #443),
/// com pendência de aprovação de administrador.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _created = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final localPart = email.contains('@') ? email.split('@').first : 'Organizador';

    try {
      await ref.read(authApiProvider).register(
            name: localPart.isEmpty ? 'Organizador' : localPart,
            email: email,
            password: _passwordController.text,
          );
      if (mounted) setState(() => _created = true);
    } on RepositoryException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = AppStrings.loginConnectionError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceMuted, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _created ? _buildSuccess(context) : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 64, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Conta criada!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Acesso liberado após aprovação de um administrador.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 24),
        KicksterButton(
          label: 'Voltar ao login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Marca compacta no topo.
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Flag Platform',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            'Criar conta',
            textAlign: TextAlign.center,
            style: AppTextStyles.headline1,
          ),
          const SizedBox(height: 8),
          const Text(
            'Solicite acesso como organizador.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 32),
          KicksterInput(
            label: AppStrings.loginEmail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.next,
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
          KicksterInput(
            label: AppStrings.loginPassword,
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(_obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            validator: (value) => (value == null || value.length < 6)
                ? 'Mínimo de 6 caracteres'
                : null,
          ),
          const SizedBox(height: 16),
          KicksterInput(
            label: 'Confirmar senha',
            controller: _confirmController,
            obscureText: _obscureConfirm,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              tooltip: _obscureConfirm ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(_obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            validator: (value) => (value != _passwordController.text)
                ? 'As senhas não coincidem'
                : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.danger, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          KicksterButton(
            label: 'Criar conta',
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
          const SizedBox(height: 24),
          const KicksterSocialDivider(),
          const SizedBox(height: 16),
          const KicksterGoogleButton(),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Já tem conta?',
                style: AppTextStyles.footerLink,
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Entrar',
                  style: AppTextStyles.footerLink
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}