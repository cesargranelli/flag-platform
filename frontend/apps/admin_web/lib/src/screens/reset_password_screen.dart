import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Passo 3 do fluxo: define a nova senha usando o token do link do e-mail.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _done = false;
  String? _errorMessage;

  @override
  void dispose() {
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

    try {
      await ref.read(authApiProvider).resetPassword(
            token: widget.token,
            newPassword: _passwordController.text,
          );
      if (mounted) setState(() => _done = true);
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
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/login'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _done ? _buildDone() : _buildForm(),
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
          const Icon(Icons.password, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Definir nova senha',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          KicksterInput(
            label: 'Nova senha',
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
            validator: (value) => (value == null || value.length < 6)
                ? 'Mínimo de 6 caracteres'
                : null,
          ),
          const SizedBox(height: 16),
          KicksterInput(
            label: 'Confirmar nova senha',
            controller: _confirmController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            validator: (value) => (value != _passwordController.text)
                ? 'As senhas não coincidem'
                : null,
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
            label: 'Redefinir senha',
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 56, color: AppColors.success),
        const SizedBox(height: 16),
        const Text(
          'Senha redefinida!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        KicksterButton(
          label: 'Ir para o login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
