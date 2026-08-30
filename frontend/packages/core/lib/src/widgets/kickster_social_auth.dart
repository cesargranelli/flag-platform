import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Divisor social "OU" do kit Kickster (issue #443).
///
/// Linhas finas 1px em [AppColors.disabled] + rótulo overline em caixa alta
/// ([AppTextStyles.overlineLabel]) — mesmo padrão do frame "Sign in" do kit
/// ("Or continue with" entre linhas).
class KicksterSocialDivider extends StatelessWidget {
  const KicksterSocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
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
}

/// Botão social Google desabilitado (issue #443).
///
/// O backend ainda não expõe OAuth — o botão fica inativo com tooltip "em
/// breve" (follow-up registrado). Cores fixas abaixo imitam marcas externas
/// (Google), exceção prevista no design system; o restante usa tokens.
class KicksterGoogleButton extends StatelessWidget {
  const KicksterGoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
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