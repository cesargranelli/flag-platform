import 'package:flag_domain/flag_domain.dart';

/// Regras de permissão de edição sobre um campeonato (issue #261).
///
/// O backend (PR #262) já bloqueia update/delete via ownership guard
/// (`assertManagedBy`); aqui a mesma regra é espelhada apenas para
/// ocultar as ações que o usuário não pode executar (UX), mantendo o
/// backend como fonte da verdade.

/// true quando [user] tem papel ADMIN da plataforma.
bool isAdminUser(User? user) => user?.role == UserRole.admin;

/// Usuário logado pode gerenciar [competition]?
///
/// Regra: ADMIN sempre pode; o criador pode editar seus campeonatos;
/// registros legados sem `createdBy` ficam restritos ao ADMIN.
/// Sem usuário logado ou sem a competição resolvida, apenas ADMIN edita.
bool canEditCompetition(User? user, Competition? competition) {
  if (isAdminUser(user)) return true;
  if (user == null || competition == null) return false;
  final createdBy = competition.createdBy;
  if (createdBy == null || createdBy.isEmpty) return false;
  return createdBy == user.id;
}
