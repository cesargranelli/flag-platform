import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Fluxo "Esqueci a senha": passo 1 (e-mail) e passo 2 (confirmação).
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
      setState(() => _sent = true);
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.loginConnectionError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/login'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent ? _buildSent() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Esqueci a senha',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Informe seu e-mail para receber o link de redefinição.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
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
                  color: Theme.of(context).colorScheme.error, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          KicksterButton(
            label: 'Enviar link de redefinição',
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
            fontWeight: FontWeight.w800,
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
