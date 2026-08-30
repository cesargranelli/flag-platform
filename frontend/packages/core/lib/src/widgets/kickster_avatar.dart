import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Avatar no estilo do kit Kickster (issue #441).
///
/// Círculo com fundo `primary` @10%, borda `line` e as iniciais (2 primeiras
/// palavras — ou 2 primeiros caracteres — do nome) em `primary` sobre
/// `surface`. Com [imageUrl] exibe a foto; sem nome, fallback para o ícone
/// `person`. Tamanho controlado por [size] (padrão 40).
class KicksterAvatar extends StatelessWidget {
  const KicksterAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 40,
    this.icon,
  });

  final String? name;
  final String? imageUrl;
  final double size;

  /// Ícone explícito (substitui as iniciais quando fornecido).
  final IconData? icon;

  /// Iniciais do nome: primeira letra do 1º e 2º termos; nome único usa os
  /// 2 primeiros caracteres.
  String get _initials {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return n.substring(0, math.min(2, n.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      alignment: Alignment.center,
      child: _buildFallbackContent(),
    );

    if (imageUrl == null) return fallback;

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Decodifica a imagem apenas na resolução necessária para o avatar
        // (evita travar listagens grandes no CanvasKit com fotos em tamanho
        // original) e usa cacheWidth/cacheHeight em pixels lógicos * DPR.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        cacheHeight: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.5,
              height: size * 0.5,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  Widget _buildFallbackContent() {
    if (icon != null) {
      return Icon(icon, size: size * 0.5, color: AppColors.primary);
    }
    if (_initials.isNotEmpty) {
      return Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          height: 1,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.primary,
        ),
      );
    }
    return Icon(Icons.person, size: size * 0.5, color: AppColors.primary);
  }
}