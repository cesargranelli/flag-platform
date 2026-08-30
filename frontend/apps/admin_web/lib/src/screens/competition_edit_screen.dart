import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/competition_form_controller.dart';
import '../widgets/competition_form_sections.dart';

/// Edição de campeonato (issue #287) — classe separada da criação.
///
/// Página única (#455): todas as seções (campeonato, modalidade, categoria,
/// temporada, conferências, agrupamento) empilhadas com títulos de seção — o
/// scroll é do body, sem barras internas. A validação cobre TODAS as seções
/// no submit.
///
/// Editável apenas em RASCUNHO. O status não é campo de formulário:
/// fica em uma faixa de estado no topo com a ação "Publicar"
/// (único caminho de publicação, com confirmação).
///
/// O estado e as regras compartilhados com a criação ficam no
/// [CompetitionFormController] (#460); as seções são os widgets de
/// `competition_form_sections.dart`.
class CompetitionEditScreen extends ConsumerStatefulWidget {
  const CompetitionEditScreen({
    super.key,
    this.competitionId,
    this.competition,
  });

  final String? competitionId;
  final Competition? competition;

  @override
  ConsumerState<CompetitionEditScreen> createState() =>
      _CompetitionEditScreenState();
}

class _CompetitionEditScreenState
    extends ConsumerState<CompetitionEditScreen> {
  final _formKey = GlobalKey<FormState>();

  CompetitionStatus _status = CompetitionStatus.draft;

  /// Modo edição busca SEMPRE a competição completa por id: o objeto vindo
  /// da listagem (extra) é shape de resumo e não tem organizationId/datas.
  bool _appliedRemote = false;

  late final CompetitionFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CompetitionFormController(
      onChanged: () {
        if (mounted) setState(() {});
      },
      competitionId: () => widget.competitionId,
      createConference: (competitionId, name) => ref
          .read(conferenceApiProvider)
          .create(competitionId: competitionId, name: name),
      deleteConference: (id) => ref.read(conferenceApiProvider).delete(id),
      createDivision: (competitionId, name, conferenceId) => ref
          .read(divisionApiProvider)
          .create(
            competitionId: competitionId,
            name: name,
            conferenceId: conferenceId,
          ),
      deleteDivision: (id) => ref.read(divisionApiProvider).delete(id),
      invalidateConferences: (competitionId) =>
          ref.invalidate(conferencesProvider(competitionId)),
      invalidateDivisions: (competitionId) =>
          ref.invalidate(divisionsProvider(competitionId)),
    );

    // Hidratação do formulário no ciclo do provider (B4 #457): em vez de
    // mutar controllers dentro do `build` (side-effect que re-hidrataria a
    // cada refetch), escuta o provider e aplica UMA vez (guard `_appliedRemote`).
    final competitionId = widget.competitionId;
    if (competitionId != null) {
      ref.listen<AsyncValue<Competition>>(
        competitionProvider(competitionId),
        (prev, next) {
          final value = next.valueOrNull;
          if (value != null && !_appliedRemote) {
            _applyCompetition(value);
          }
        },
      );
    }
  }

  /// Hidrata o formulário a partir da competição carregada (uma única vez).
  void _applyCompetition(Competition competition) {
    _controller.resetFor(competition);
    _status = competition.status;
    _appliedRemote = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Valida TODAS as seções no submit (#455): form (identidade + datas),
  /// modalidade e categoria — como o wizard exigia antes de salvar.
  bool _validateAll() {
    if (!_formKey.currentState!.validate()) return false;
    if (!_controller.validateSelections()) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_validateAll()) return;

    final c = _controller;
    c.submitting = true;
    c.errorMessage = null;
    c.onChanged();

    try {
      final api = ref.read(competitionApiProvider);
      final id = widget.competitionId!;
      // O status persistido é sempre o atual: publicação é uma ação
      // dedicada (_publish), não um campo do formulário.
      await api.update(
        id,
        organizationId: c.organizationId.text.trim(),
        name: c.name.text.trim(),
        description: c.description.text.trim().isEmpty
            ? null
            : c.description.text.trim(),
        startDate: c.startDate.text.isEmpty ? null : c.startDate.text,
        endDate: c.endDate.text.isEmpty ? null : c.endDate.text,
        status: _status,
        modality: c.modality,
        gender: c.gender?.toJson(),
        ageGroup: c.ageGroup?.toJson(),
        groupingType: c.groupingChoice,
      );
      ref.invalidate(competitionsProvider);
      ref.invalidate(competitionProvider(id));

      c.saved = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campeonato salvo com sucesso')),
        );
        context.go('/competitions/$id');
      }
    } on RepositoryException catch (e) {
      c.errorMessage = e.message;
      c.onChanged();
    } catch (_) {
      c.errorMessage = 'Não foi possível salvar o campeonato.';
      c.onChanged();
    } finally {
      c.submitting = false;
      if (mounted) c.onChanged();
    }
  }

  /// Publica o campeonato (DRAFT → PUBLISHED), ação irreversível com
  /// confirmação. Após publicar, retorna ao detalhe (edição fica travada).
  Future<void> _publish() async {
    final confirmed = await showKicksterConfirm(
      context: context,
      title: 'Publicar campeonato',
      content: 'Após publicar, o campeonato não poderá mais ser editado.',
      confirmLabel: 'Publicar',
      danger: true,
    );
    if (confirmed != true || !mounted) return;

    final c = _controller;
    c.submitting = true;
    c.errorMessage = null;
    c.onChanged();

    try {
      final api = ref.read(competitionApiProvider);
      final id = widget.competitionId!;
      await api.update(
        id,
        organizationId: c.organizationId.text.trim(),
        name: c.name.text.trim(),
        description: c.description.text.trim().isEmpty
            ? null
            : c.description.text.trim(),
        startDate: c.startDate.text.isEmpty ? null : c.startDate.text,
        endDate: c.endDate.text.isEmpty ? null : c.endDate.text,
        status: CompetitionStatus.published,
        modality: c.modality,
        gender: c.gender?.toJson(),
        ageGroup: c.ageGroup?.toJson(),
        groupingType: c.groupingChoice,
      );
      ref.invalidate(competitionsProvider);
      ref.invalidate(competitionProvider(id));
      c.saved = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campeonato publicado')),
        );
        context.go('/competitions/$id');
      }
    } on RepositoryException catch (e) {
      c.errorMessage = e.message;
      c.onChanged();
    } catch (_) {
      c.errorMessage = 'Não foi possível publicar o campeonato.';
      c.onChanged();
    } finally {
      c.submitting = false;
      if (mounted) c.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncComp = ref.watch(competitionProvider(widget.competitionId!));
    return asyncComp.when(
      loading: () => AppScreen(
        title: 'Editar campeonato',
        breadcrumb: [
          const BreadcrumbItem('Início', route: '/'),
          const BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
          if (widget.competition?.name != null)
            BreadcrumbItem(widget.competition!.name),
        ],
        body: const AppLoading(message: 'Carregando campeonato...'),
      ),
      error: (error, stackTrace) => AppScreen(
        title: 'Editar campeonato',
        breadcrumb: [
          const BreadcrumbItem('Início', route: '/'),
          const BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
          if (widget.competition?.name != null)
            BreadcrumbItem(widget.competition!.name),
        ],
        body: AppErrorState(
          message: 'Não foi possível carregar o campeonato',
          onRetry: () =>
              ref.invalidate(competitionProvider(widget.competitionId!)),
        ),
      ),
      data: (competition) {
        // Issue #261: sem permissão (criador/ADMIN), estado informativo.
        final user = ref.watch(authControllerProvider.select((a) => a.state.user));
        if (!canEditCompetition(user, competition)) {
          return AppScreen(
            title: 'Editar campeonato',
            breadcrumb: [
              const BreadcrumbItem('Início', route: '/'),
              const BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
              BreadcrumbItem(competition.name),
            ],
            body: const AppEmptyState(
              message: 'Você não tem permissão para editar este campeonato.',
              icon: Icons.lock_outline,
            ),
          );
        }
        // Issue #257 (M4): apenas RASCUNHO é editável.
        if (competition.status != CompetitionStatus.draft) {
          return AppScreen(
            title: 'Editar campeonato',
            breadcrumb: [
              const BreadcrumbItem('Início', route: '/'),
              const BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
              BreadcrumbItem(competition.name),
            ],
            body: AppEmptyState(
              message: competition.status == CompetitionStatus.published
                  ? 'Campeonato publicado — não é mais editável.'
                  : 'Campeonato '
                         '${_statusLabel(competition.status).toLowerCase()} — '
                         'não é mais editável.',
              icon: Icons.lock,
            ),
          );
        }
        return _buildEditable(context);
      },
    );
  }

  Widget _buildEditable(BuildContext context) {
    final c = _controller;
    return PopScope(
      canPop: !c.hasChanges || c.submitting || c.saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) c.handleBack(context, isMounted: () => mounted);
      },
      child: AppScreen(
        title: 'Editar campeonato',
        breadcrumb: [
          const BreadcrumbItem('Início', route: '/'),
          const BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
          if (c.name.text.isNotEmpty) BreadcrumbItem(c.name.text),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppLayout.form(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Faixa de estado do status (issue #287): chip + Publicar.
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      decoration: BoxDecoration(
                        color: AppColors.grayFill.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grayFill),
                      ),
                      child: Row(
                        children: [
                          _statusChip(_status),
                          const Spacer(),
                          KicksterButton(
                            label: 'Publicar',
                            icon: Icons.publish_outlined,
                            variant: KicksterButtonVariant.outline,
                            onPressed: c.submitting ? null : _publish,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (c.errorMessage != null)
                      competitionErrorBanner(c.errorMessage!),
                    competitionSection(
                      title: 'Campeonato',
                      icon: Icons.emoji_events_outlined,
                      child: CompetitionIdentitySection(
                        controller: c,
                        dropdownKeyPrefix: 'edit',
                        onOrganizationChanged: () => setState(() {}),
                      ),
                    ),
                    competitionSection(
                      title: 'Modalidade',
                      icon: Icons.sports_football_outlined,
                      child: CompetitionModalitySection(
                        controller: c,
                        title: 'Modalidade',
                      ),
                    ),
                    competitionSection(
                      title: 'Categoria',
                      icon: Icons.groups_outlined,
                      child: CompetitionCategorySection(controller: c),
                    ),
                    competitionSection(
                      title: 'Temporada',
                      icon: Icons.date_range,
                      child: CompetitionSeasonSection(
                        controller: c,
                        isMounted: () => mounted,
                      ),
                    ),
                    competitionSection(
                      title: 'Conferências',
                      icon: Icons.account_tree_outlined,
                      child: CompetitionConferencesSection(
                        controller: c,
                        competitionId: widget.competitionId,
                      ),
                    ),
                    competitionSection(
                      title: 'Agrupamento',
                      icon: Icons.hub_outlined,
                      child: CompetitionStructureSection(
                        controller: c,
                        competitionId: widget.competitionId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    KicksterButton(
                      label: 'Salvar',
                      icon: Icons.check,
                      loading: c.submitting,
                      onPressed: c.submitting ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(CompetitionStatus status) {
    // Status neutro no form de edição (era grayFill/textPrimary bold):
    // token neutro mais próximo do design system (regra da Família 3).
    return KicksterBadge(
      label: _statusLabel(status),
      color: AppColors.textSecondary,
    );
  }

  String _statusLabel(CompetitionStatus status) => switch (status) {
        CompetitionStatus.draft => 'Rascunho',
        CompetitionStatus.published => 'Publicado',
        CompetitionStatus.finished => 'Encerrado',
        CompetitionStatus.disabled => 'Desativado',
      };
}