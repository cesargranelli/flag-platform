import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../utils/date_formats.dart';
import '../widgets/app_screen.dart';
import '../widgets/competition_form_controller.dart';
import '../widgets/competition_form_sections.dart';

/// CRIAÇÃO de campeonato em página única (#455): todas as seções
/// (campeonato, modalidade, categoria, temporada, conferências, agrupamento)
/// empilhadas com títulos de seção — o scroll é do body, sem barras internas.
///
/// O botão "Criar campeonato" valida as seções de cadastro e grava o
/// campeonato (sempre RASCUNHO), habilitando a seguir as seções de estrutura
/// (Conferências → Agrupamento: Divisões ou Grupos), ambas com opção de
/// declínio — o fluxo nunca trava. Após configurar, "Concluir" persiste a
/// escolha de agrupamento e vai ao detalhe (issues #287/#304/#338).
///
/// O estado e as regras compartilhados com a edição ficam no
/// [CompetitionFormController] (#460); as seções são os widgets de
/// `competition_form_sections.dart`.
class CompetitionCreateScreen extends ConsumerStatefulWidget {
  const CompetitionCreateScreen({super.key});

  @override
  ConsumerState<CompetitionCreateScreen> createState() =>
      _CompetitionCreateScreenState();
}

class _CompetitionCreateScreenState
    extends ConsumerState<CompetitionCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Campeonato recém-criado — alimenta as seções de estrutura (#304).
  Competition? _created;

  late final CompetitionFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CompetitionFormController(
      onChanged: () {
        if (mounted) setState(() {});
      },
      competitionId: () => _created?.id,
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ação principal: antes do rascunho criado, valida TODAS as seções de
  /// cadastro (form + modalidade + categoria) e grava o RASCUNHO; depois,
  /// persiste a escolha de agrupamento e vai ao detalhe (#455).
  Future<void> _submit() async {
    if (_created != null) {
      await _finish();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_controller.validateSelections()) return;
    await _createDraft();
  }

  /// Cria o campeonato em RASCUNHO e habilita as seções de estrutura (#304).
  Future<void> _createDraft() async {
    final c = _controller;
    c.submitting = true;
    c.errorMessage = null;
    c.onChanged();

    try {
      final api = ref.read(competitionApiProvider);
      final created = await api.create(
        organizationId: c.organizationId.text.trim(),
        name: c.name.text.trim(),
        description: c.description.text.trim().isEmpty
            ? null
            : c.description.text.trim(),
        startDate: c.startDate.text.isEmpty ? null : c.startDate.text,
        endDate: c.endDate.text.isEmpty ? null : c.endDate.text,
        modality: c.modality,
        gender: c.gender?.toJson(),
        ageGroup: c.ageGroup?.toJson(),
      );

      ref.invalidate(competitionsProvider);
      ref.invalidate(competitionProvider(created.id));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rascunho criado — agora configure a estrutura.'),
        ),
      );
      setState(() {
        _created = created;
        c.errorMessage = null;
      });
    } on RepositoryException catch (e) {
      c.errorMessage = e.message;
      c.onChanged();
    } catch (_) {
      c.errorMessage = 'Não foi possível criar o campeonato.';
      c.onChanged();
    } finally {
      c.submitting = false;
      if (mounted) c.onChanged();
    }
  }

  /// Persiste a escolha de agrupamento (quando houver) e vai ao detalhe.
  Future<void> _finish() async {
    final c = _controller;
    final created = _created!;
    final needsUpdate =
        !c.declinedStructure && c.groupingChoice != created.groupingType;

    if (needsUpdate) {
      c.submitting = true;
      c.errorMessage = null;
      c.onChanged();
      try {
        final api = ref.read(competitionApiProvider);
        final updated = await api.update(
          created.id,
          organizationId: created.organizationId!,
          name: created.name,
          description: created.description,
          startDate: formatIsoDate(created.startDate),
          endDate: formatIsoDate(created.endDate),
          status: created.status,
          modality: created.modality,
          gender: created.gender,
          ageGroup: created.ageGroup,
          groupingType: c.groupingChoice,
        );
        ref.invalidate(competitionProvider(created.id));
        _created = updated;
      } on RepositoryException catch (e) {
        c.errorMessage = e.message;
        c.onChanged();
        return;
      } catch (_) {
        c.errorMessage = 'Não foi possível salvar o tipo de agrupamento.';
        c.onChanged();
        return;
      } finally {
        c.submitting = false;
        if (mounted) c.onChanged();
      }
    }

    c.saved = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rascunho criado. Abra o campeonato para publicar quando '
            'estiver pronto.',
          ),
        ),
      );
      context.go('/competitions/${_created!.id}', extra: _created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return PopScope(
      canPop: !c.hasChanges || c.submitting || c.saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) c.handleBack(context, isMounted: () => mounted);
      },
      child: AppScreen(
        title: 'Novo campeonato',
        breadcrumb: const [
          BreadcrumbItem('Início', route: '/'),
          BreadcrumbItem(AppStrings.competitions, route: '/competitions'),
          BreadcrumbItem('Novo'),
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
                    if (c.errorMessage != null)
                      competitionErrorBanner(c.errorMessage!),
                    competitionSection(
                      title: 'Campeonato',
                      icon: Icons.emoji_events_outlined,
                      child: CompetitionIdentitySection(
                        controller: c,
                        dropdownKeyPrefix: 'create',
                        preselectSingle: true,
                        showPreselectedLabel: true,
                      ),
                    ),
                    competitionSection(
                      title: 'Modalidade',
                      icon: Icons.sports_football_outlined,
                      child: CompetitionModalitySection(controller: c),
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
                        showSummary: true,
                        isMounted: () => mounted,
                      ),
                    ),
                    competitionSection(
                      title: 'Conferências',
                      icon: Icons.account_tree_outlined,
                      child: CompetitionConferencesSection(
                        controller: c,
                        competitionId: _created?.id,
                      ),
                    ),
                    competitionSection(
                      title: 'Agrupamento',
                      icon: Icons.hub_outlined,
                      child: CompetitionStructureSection(
                        controller: c,
                        competitionId: _created?.id,
                      ),
                    ),
                    const SizedBox(height: 8),
                    KicksterButton(
                      label: _created == null
                          ? 'Criar campeonato'
                          : 'Concluir',
                      icon: _created == null
                          ? Icons.check
                          : Icons.check_circle_outline,
                      loading: c.submitting,
                      onPressed: c.submitting ? null : _submit,
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
}