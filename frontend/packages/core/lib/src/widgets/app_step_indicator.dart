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
    this.showDoneState = true,
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

  /// Marca como concluídas (verde) as etapas anteriores à ativa. Desligue
  /// (`false`) em navegações de leitura (telas de detalhe) para que apenas a
  /// etapa ativa fique selecionada e as demais permaneçam "não selecionadas".
  final bool showDoneState;

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
    // Em leitura (detalhe) o "concluído" fica desligado: só a etapa ativa é
    // selecionada; as demais permanecem "não selecionadas" (gris), sem o verde.
    final done = showDoneState && index < currentStep;
    final useIcons = icons != null;

    final CircleAvatar circle;
    if (useIcons) {
      circle = CircleAvatar(
        radius: 14,
        backgroundColor: selected ? AppColors.primary : AppColors.grayFill,
        child: Icon(
          icons![index],
          size: 18,
          color: selected ? Colors.white : AppColors.textPrimary,
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

    // No modo ícones, o item selecionado fica com fundo `primary` (todo
    // laranja) e conteúdo BRANCO (ícone + rótulo) (#332).
    return Semantics(
      selected: selected,
      button: true,
      label: 'Etapa ${index + 1}',
      child: InkWell(
        onTap: () => onStepTap?.call(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: useIcons && selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
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
                    color: useIcons
                        ? (selected
                            ? Colors.white
                            : AppColors.textSecondary)
                        : (selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary),
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
