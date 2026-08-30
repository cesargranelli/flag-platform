import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Fluxo "Esqueci a senha" no visual do kit Kickster (issue #443):
/// passo 1 (e-mail) e passo 2 (confirmação).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _sent = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authApiProvider)
          .forgotPassword(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
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
                child: _sent ? _buildSent() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Esqueci a senha',
            textAlign: TextAlign.center,
            style: AppTextStyles.headline1,
          ),
          const SizedBox(height: 8),
          const Text(
            'Recupere a senha da sua conta',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 32),
          KicksterInput(
            label: AppStrings.loginEmail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppStrings.loginRequiredEmail;
              }
              if (!value.contains('@')) {
                return AppStrings.loginInvalidEmail;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.danger, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          KicksterButton(
            label: 'Enviar link',
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }

  Widget _buildSent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        const Text(
          'Enviamos um link para seu e-mail',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Use o link recebido para definir uma nova senha.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        KicksterButton(
          label: 'Voltar ao login',
          variant: KicksterButtonVariant.outline,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}