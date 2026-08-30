import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela de login do Admin Web no visual do kit Kickster (issue #443).
///
/// Formulário centralizado (sem split): marca compacta, saudação, campos
/// `KicksterInput`, manter conectado/esqueci a senha, botão primário,
/// divisor social "OU" e ação Google desabilitada (backend ainda sem OAuth —
/// follow-up registrado).
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        _errorBanner(_errorMessage!),
                        const SizedBox(height: 16),
                      ],
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
                        'Acesse sua conta',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 32),
                      KicksterInput(
                        label: AppStrings.loginEmail,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
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
                          tooltip: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? AppStrings.loginRequiredPassword
                                : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          KicksterCheckbox(
                            value: _keepConnected,
                            onChanged: (value) => setState(
                                () => _keepConnected = value),
                            label: 'Manter conectado',
                          ),
                          TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: Text(
                              'Esqueci a senha',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      KicksterButton(
                        label: AppStrings.loginSubmit,
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
                        spacing: 4,
                        children: [
                          const Text(
                            'Não tem conta?',
                            style: AppTextStyles.footerLink,
                          ),
                          TextButton(
                            onPressed: () => context.go('/signup'),
                            child: Text(
                              'Criar conta',
                              style: AppTextStyles.footerLink.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Banner de erro no topo do formulário (padrão danger tint de
  /// competition_form_screen._errorBanner).
  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  AppTextStyles.paragraph.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}