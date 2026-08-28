import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breadcrumb do Admin Web (issue #427), derivado do caminho da URL.
///
/// Ex.: `/competitions/123/edit` → `Campeonatos › Estadual › Editar`.
/// Itens anteriores são clicáveis (`context.go`); o último (página atual) é
/// texto `textPrimary` w700. O nome da entidade no segmento `:id` vem do
/// `extra` da navegação quando disponível; em deep links cai para "Detalhe".
class AdminBreadcrumbs extends StatelessWidget {
  const AdminBreadcrumbs({
    super.key,
    required this.location,
    required this.extra,
  });

  final String location;
  final Object? extra;

  @override
  Widget build(BuildContext context) {
    final crumbs = _buildCrumbs();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            for (var i = 0; i < crumbs.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '›',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              _crumb(context, crumbs[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _crumb(BuildContext context, ({String label, String? route}) crumb) {
    final route = crumb.route;
    if (route == null) {
      return Text(
        crumb.label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
    }
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          crumb.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Constrói a lista de migalhas: rótulo + rota clicável (null no último).
  List<({String label, String? route})> _buildCrumbs() {
    if (location == '/') {
      return [(label: 'Início', route: null)];
    }
    final parts = location.split('/').where((s) => s.isNotEmpty).toList();
    final crumbs = <({String label, String? route})>[];
    var prefix = '';
    for (var i = 0; i < parts.length; i++) {
      prefix = '$prefix/${parts[i]}';
      final isLast = i == parts.length - 1;
      crumbs.add((
        label: _labelFor(parts[i], isLast ? extra : null),
        route: isLast ? null : prefix,
      ));
    }
    return crumbs;
  }

  String _labelFor(String segment, Object? extra) {
    switch (segment) {
      case 'organizations':
        return 'Organizações';
      case 'competitions':
        return 'Campeonatos';
      case 'groupings':
        return 'Conferências e divisões';
      case 'venues':
        return 'Campos';
      case 'teams':
        return 'Times';
      case 'athletes':
        return 'Atletas';
      case 'rosters':
        return 'Elencos';
      case 'rounds':
        return 'Rodadas';
      case 'games':
        return 'Jogos';
      case 'users':
        return 'Usuários';
      case 'approvals':
        return 'Aprovações';
      case 'visual-test':
        return 'Teste visual';
      case 'new':
        return 'Novo';
      case 'edit':
        return 'Editar';
      case 'import':
        return 'Importar';
      case 'associate':
        return 'Associar clubes';
      case 'roster':
        return 'Elenco';
    }
    // Segmento de entidade (`:id`): tenta nomear pelo extra da navegação.
    final name = _entityName(extra);
    return name ?? 'Detalhe';
  }

  String? _entityName(Object? extra) {
    if (extra is Organization) return extra.tradeName;
    if (extra is Competition) return extra.name;
    if (extra is Team) return extra.name;
    if (extra is Athlete) return extra.name;
    if (extra is Venue) return extra.name;
    if (extra is Round) return extra.name;
    if (extra is Game) return extra.homeTeamName;
    return null;
  }
}