import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Abas no estilo do kit Kickster (issue #441).
///
/// Rótulo 14px w600, aba inativa em `textSecondary` e a ativa em
/// `textPrimary` com indicador inferior `primary` (underline 3px, raio 2).
/// Seleção controlada pelo chamador via [currentIndex]/[onChanged].
class KicksterTabs extends StatelessWidget {
  const KicksterTabs({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          _buildTab(i),
          if (i < tabs.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }

  Widget _buildTab(int index) {
    final selected = index == currentIndex;
    return InkWell(
      onTap: () => onChanged(index),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              tabs[index],
              style: TextStyle(
                fontSize: 14,
                height: 22 / 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.07,
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          // Indicador inferior na largura do rótulo (a coluna encolhe ao
          // texto; a margem horizontal deixa a barra alinhada ao label).
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}