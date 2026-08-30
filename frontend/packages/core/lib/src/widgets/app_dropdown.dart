import 'package:flutter/material.dart';

import 'package:flag_domain/flag_domain.dart';

import '../theme/app_colors.dart';

/// Item de dropdown com ícone à esquerda (issue #365).
///
/// Usado nos seletores de entidades (organizações/clubes, campeonatos,
/// tipos de organização) para dar contexto visual ao item dentro do menu
/// aberto e no valor selecionado. Mantém o rótulo em uma linha com ellipsis,
/// respeitando a largura do campo.
Widget appDropdownItem(IconData? icon, String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 20, color: AppColors.primary),
        if (icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

/// Ícone correspondente ao tipo de organização (issue #365).
IconData organizationTypeIcon(OrganizationType? type) => switch (type) {
      OrganizationType.federation => Icons.account_balance_outlined,
      OrganizationType.league => Icons.emoji_events_outlined,
      OrganizationType.association => Icons.groups_outlined,
      OrganizationType.university => Icons.school_outlined,
      OrganizationType.club => Icons.shield_outlined,
      OrganizationType.other => Icons.business_outlined,
      null => Icons.business_outlined,
    };
