import 'dart:math' as math;

import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Tela de login do Admin Web (tema claro Shifty, layout split).
///
/// Formulário conforme spec do Figma (UI Kit Shifty): coluna alinhada à
/// esquerda com marca compacta, H1, subtítulo, campos, divisor "OU" e ação
/// social desabilitada (backend ainda sem OAuth — follow-up registrado).
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
              if (_errorMessage != null) ...[
                _errorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              // Marca compacta no topo.
              Row(
                children: [
                  const Icon(Icons.sports, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Flag Platform',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Acesse sua conta', style: AppTextStyles.headline1),
              const SizedBox(height: 8),
              Text(AppStrings.loginSubtitle, style: AppTextStyles.subtitle),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _keepConnected,
                        onChanged: (value) =>
                            setState(() => _keepConnected = value ?? false),
                      ),
                      Text(
                        'Manter conectado',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
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
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.loginSubmit,
                        style: AppTextStyles.buttonText),
              ),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 16),
              _buildGoogleButton(context),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  const Text('Não tem conta?', style: AppTextStyles.footerLink),
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
    );
  }

  /// Divisor "OU": linhas finas 1px (`disabled`) + overline em `grayLabel`.
  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.disabled, thickness: 1, height: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('OU', style: AppTextStyles.overlineLabel),
        ),
        Expanded(
          child: Divider(color: AppColors.disabled, thickness: 1, height: 1),
        ),
      ],
    );
  }

  /// Botão social desabilitado (backend sem OAuth): fundo `surfaceMuted`,
  /// ícone G multicolor via CustomPaint e tooltip explicativo.
  Widget _buildGoogleButton(BuildContext context) {
    return Tooltip(
      message: 'Login com Google em breve',
      child: Semantics(
        button: true,
        enabled: false,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(painter: _GoogleLogoPainter(), size: Size(22, 22)),
              SizedBox(width: 12),
              Text(
                'Continuar com Google',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: Color(0xFF171717),
                ),
              ),
            ],
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

  Widget _buildArt(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3EB), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Icon(
              Icons.sports_soccer,
              size: 320,
              color: AppColors.primary.withValues(alpha: 0.08),
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
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'O melhor lugar para acompanhar um campeonato de flag',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Organize, acompanhe e viva o jogo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
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

/// Desenha o "G" do Google com quatro arcos + barra horizontal.
/// Aproximação da marca (cores oficiais) sem depender de asset.
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    double rad(double deg) => deg * math.pi / 180;

    // Vermelho — arco superior.
    paint.color = _red;
    canvas.drawArc(rect, rad(206), rad(124), false, paint);

    // Amarelo — quadrante inferior esquerdo.
    paint.color = _yellow;
    canvas.drawArc(rect, rad(102), rad(49), false, paint);

    // Verde — base até a abertura inferior direita.
    paint.color = _green;
    canvas.drawArc(rect, rad(61), rad(42), false, paint);

    // Azul — lado esquerdo + barra horizontal do "G".
    paint.color = _blue;
    canvas.drawArc(rect, rad(150), rad(57), false, paint);
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width - stroke / 2, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
