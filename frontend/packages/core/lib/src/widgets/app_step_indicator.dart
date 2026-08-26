import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indicador de passos do wizard (navegação por sessões, #323).
///
/// Encapsula o padrão antes duplicado nas telas de cadastro/edição, com três
/// estados: **concluído** (círculo `success`, check branco), **selecionado**
/// (círculo `primary`, ponto branco) e **pendente** (círculo `grayFill`,
/// número ordinal). A decisão de navegação (avanço sequencial/volta livre)
/// pertence ao pai, via [onStepTap].
///
/// Quando [icons] é fornecido (telas de detalhe, #332), cada círculo exibe o
/// **ícone da sessão** no lugar do número/ponto — a cor do círculo continua
/// comunicando o estado.
class AppStepIndicator extends StatelessWidget {
  const AppStepIndicator({
    super.key,
    required this.titles,
    this.icons,
    required this.currentStep,
    this.onStepTap,
  });

  /// Rótulos de cada etapa (índice = passo).
  final List<String> titles;

  /// Ícones representativos de cada sessão (paralelo a [titles], mesmo
  /// comprimento). Quando fornecido, cada círculo exibe o ícone da sessão no
  /// lugar do número/ponto (usado nas telas de detalhe, #332).
  final List<IconData>? icons;

  /// Índice da etapa ativa.
  final int currentStep;

  /// Chamado ao tocar em uma etapa; a regra de navegação é do pai.
  final void Function(int index)? onStepTap;

  @override
  Widget build(BuildContext context) {
    assert(
      icons == null || icons?.length == titles.length,
      'AppStepIndicator: "icons" (${icons?.length}) e "titles"'
      ' (${titles.length}) devem ter o mesmo tamanho.',
    );
    return Row(
      children: [
        for (var i = 0; i < titles.length; i++) Expanded(child: _stepItem(i)),
      ],
    );
  }

  Widget _stepItem(int index) {
    final selected = index == currentStep;
    final done = index < currentStep;
    final CircleAvatar circle;
    if (icons != null) {
      // Modo "ícones" (telas de detalhe): o ícone da sessão identifica cada
      // etapa e a cor do círculo comunica o estado (#332).
      circle = CircleAvatar(
        radius: 14,
        backgroundColor: done
            ? AppColors.success
            : selected
                ? AppColors.primary
                : AppColors.grayFill,
        child: Icon(
          icons![index],
          size: 18,
          color:
              (done || selected) ? Colors.white : AppColors.textPrimary,
        ),
      );
    } else if (done) {
      circle = const CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.success,
        child: Icon(Icons.check, size: 20, color: Colors.white),
      );
    } else if (selected) {
      circle = const CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.circle, size: 8, color: Colors.white),
      );
    } else {
      circle = CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.grayFill,
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      label: 'Etapa ${index + 1}',
      child: InkWell(
        onTap: () => onStepTap?.call(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              circle,
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  titles[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
