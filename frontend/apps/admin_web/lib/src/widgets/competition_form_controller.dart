import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/date_formats.dart';

/// Controller compartilhado do formulário de campeonato (criar/editar).
///
/// Consolida o estado e as regras duplicados entre `CompetitionCreateScreen`
/// e `CompetitionEditScreen` (#460): 7 `TextEditingController`, seleções
/// (modalidade/gênero/faixa etária), escolha de agrupamento, declínios,
/// dirty tracking e os métodos de estrutura (conferências/divisões).
///
/// Classe **pura**: não depende de `WidgetRef`/providers. As chamadas de API
/// são injetadas como callbacks pelo host (tela), que também provê o
/// `competitionId` vigente (`null` no create antes de o rascunho existir,
/// desabilitando as seções de estrutura) e o callback `onChanged`, que
/// dispara o rebuild da tela (equivalente ao `setState` original).
class CompetitionFormController {
  CompetitionFormController({
    required this.onChanged,
    required this.competitionId,
    required this.createConference,
    required this.deleteConference,
    required this.createDivision,
    required this.deleteDivision,
    required this.invalidateConferences,
    required this.invalidateDivisions,
  }) {
    for (final c in [name, description, organizationId, startDate, endDate]) {
      c.addListener(markDirty);
    }
  }

  /// Rebuild da tela (setState do host). Necessário após qualquer mutação de
  /// estado que precise refletir na UI (o padrão original era `setState`).
  final VoidCallback onChanged;

  /// Id do campeonato vigente — `null` no create antes do rascunho criado.
  final String? Function() competitionId;

  // ── Dependências de API (injetadas pelo host via ref.read) ──────────────

  /// Cria uma conferência na competição [competitionId].
  final Future<void> Function(String competitionId, String name)
      createConference;

  /// Exclui uma conferência pelo id.
  final Future<void> Function(String id) deleteConference;

  /// Cria uma divisão/grupo na competição [competitionId].
  final Future<void> Function(
    String competitionId,
    String name,
    String? conferenceId,
  ) createDivision;

  /// Exclui uma divisão/grupo pelo id.
  final Future<void> Function(String id) deleteDivision;

  /// Invalida `conferencesProvider(competitionId)` após mutações.
  final void Function(String competitionId) invalidateConferences;

  /// Invalida `divisionsProvider(competitionId)` após mutações.
  final void Function(String competitionId) invalidateDivisions;

  // ── Controllers ─────────────────────────────────────────────────────────

  late final TextEditingController name;
  late final TextEditingController description;
  late final TextEditingController organizationId;
  late final TextEditingController startDate;
  late final TextEditingController endDate;
  final conferenceName = TextEditingController();
  final divisionName = TextEditingController();

  // ── Seleções ────────────────────────────────────────────────────────────

  Modality? modality;
  Gender? gender;
  AgeGroup? ageGroup;
  GroupingType? groupingChoice;
  String? conferenceId;
  bool declinedConferences = false;
  bool declinedStructure = false;

  // ── Flags de UI ─────────────────────────────────────────────────────────

  bool submitting = false;
  bool saved = false;
  bool hasChanges = false;
  bool populating = false;
  String? errorMessage;

  // ── Erros de seção (modalidade/categoria) ───────────────────────────────

  String? modalityError;
  String? categoryError;

  DateTime? get parsedStartDate => DateTime.tryParse(startDate.text.trim());

  /// "grupos" ou "divisões" conforme a escolha de agrupamento.
  String get itemLabelLower =>
      groupingChoice == GroupingType.groups ? 'grupos' : 'divisões';

  /// Marca o formulário como alterado — fiel ao `_markDirty` original:
  /// suprime durante hidratação, após salvar e quando já está marcado.
  void markDirty() {
    if (populating || saved || hasChanges) return;
    hasChanges = true;
    onChanged();
  }

  /// Marca dirty E garante rebuild (usado onde o original tinha
  /// `setState(...)` + `_markDirty()` — o setState sempre rebuildava).
  void _touch() {
    if (!populating && !saved) hasChanges = true;
    onChanged();
  }

  // ── Seleções de modalidade/categoria ────────────────────────────────────

  void selectModality(Modality value) {
    modality = value;
    modalityError = null;
    _touch();
  }

  void selectGender(Gender value) {
    gender = value;
    categoryError = null;
    _touch();
  }

  void selectAgeGroup(AgeGroup value) {
    ageGroup = value;
    categoryError = null;
    _touch();
  }

  /// Valida as seleções de modalidade/categoria na ordem exata do submit
  /// original (form → modalidade → gênero/faixa) e notifica para exibir os
  /// erros de seção.
  bool validateSelections() {
    if (modality == null) {
      modalityError = 'Selecione a modalidade';
      onChanged();
      return false;
    }
    if (gender == null || ageGroup == null) {
      categoryError =
          gender == null ? 'Selecione o gênero' : 'Selecione a faixa etária';
      onChanged();
      return false;
    }
    return true;
  }

  /// Hidrata o formulário a partir de uma competição (edição, #457).
  /// Não dispara rebuild — o host decide quando chamar `onChanged`.
  void resetFor(Competition competition) {
    populating = true;
    name.text = competition.name;
    description.text = competition.description ?? '';
    organizationId.text = competition.organizationId ?? '';
    startDate.text = formatIsoDate(competition.startDate);
    endDate.text = formatIsoDate(competition.endDate);
    modality = competition.modality;
    gender =
        competition.gender == null ? null : Gender.fromJson(competition.gender!);
    ageGroup = competition.ageGroup == null
        ? null
        : AgeGroup.fromJson(competition.ageGroup!);
    groupingChoice = competition.groupingType;
    populating = false;
  }

  /// Abre o calendário do design system e aplica a data (ISO) no controller.
  /// `isMounted` preserva o guard `mounted` do host após o `await`.
  Future<void> pickDate(
    BuildContext context,
    TextEditingController controller, {
    DateTime? minDate,
    bool Function()? isMounted,
  }) async {
    final now = DateTime.now();
    final firstDate = minDate ?? DateTime(2000);
    final parsed = DateTime.tryParse(controller.text);
    var initialDate = parsed ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(DateTime(2100))) initialDate = DateTime(2100);
    final picked = await showAppCalendarDialog(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && (isMounted?.call() ?? true)) {
      controller.text = formatIsoDate(picked);
    }
  }

  // ── Declínios e agrupamento (estrutura) ─────────────────────────────────

  /// "Este campeonato não usa conferências" (#304/#345).
  void declineConferences() {
    declinedConferences = true;
    _touch();
  }

  /// Reverte o declínio de conferências ("Usar conferências").
  void undoDeclineConferences() {
    declinedConferences = false;
    onChanged();
  }

  /// Seleciona Divisões ou Grupos (limpa o declínio de estrutura).
  void selectGrouping(GroupingType type) {
    groupingChoice = type;
    declinedStructure = false;
    _touch();
  }

  /// "Não usar divisões nem grupos".
  void declineStructure() {
    declinedStructure = true;
    groupingChoice = null;
    _touch();
  }

  /// Seleção de conferência no dropdown de Agrupamento (#338).
  void selectConference(String? value) {
    conferenceId = (value == null || value.isEmpty) ? null : value;
    onChanged();
  }

  // ── Estrutura: conferências/divisões (chamadas de API injetadas) ────────

  Future<void> addConference() async {
    final id = competitionId();
    final cname = conferenceName.text.trim();
    if (cname.isEmpty || id == null) return;
    submitting = true;
    onChanged();
    try {
      await createConference(id, cname);
      conferenceName.clear();
      invalidateConferences(id);
      markDirty();
    } on RepositoryException catch (e) {
      errorMessage = e.message;
      onChanged();
    } catch (_) {
      errorMessage = 'Não foi possível adicionar.';
      onChanged();
    } finally {
      submitting = false;
      onChanged();
    }
  }

  Future<void> addDivision() async {
    final id = competitionId();
    final dname = divisionName.text.trim();
    if (dname.isEmpty || id == null || groupingChoice == null) return;
    submitting = true;
    onChanged();
    try {
      await createDivision(id, dname, conferenceId);
      divisionName.clear();
      invalidateDivisions(id);
      markDirty();
    } on RepositoryException catch (e) {
      errorMessage = e.message;
      onChanged();
    } catch (_) {
      errorMessage = 'Não foi possível adicionar.';
      onChanged();
    } finally {
      submitting = false;
      onChanged();
    }
  }

  Future<void> removeConference(Conference conference) async {
    final id = competitionId();
    if (id == null) return;
    submitting = true;
    onChanged();
    try {
      await deleteConference(conference.id);
      // Se a conferência removida era a selecionada no Agrupamento, zera a seleção.
      if (conferenceId == conference.id) conferenceId = null;
      invalidateConferences(id);
      invalidateDivisions(id); // conferência pode ter divisões (cascade)
      markDirty();
    } on RepositoryException catch (e) {
      errorMessage = e.message;
      onChanged();
    } catch (_) {
      errorMessage = 'Não foi possível remover.';
      onChanged();
    } finally {
      submitting = false;
      onChanged();
    }
  }

  Future<void> removeDivision(Division division) async {
    final id = competitionId();
    if (id == null) return;
    submitting = true;
    onChanged();
    try {
      await deleteDivision(division.id);
      invalidateDivisions(id);
      markDirty();
    } on RepositoryException catch (e) {
      errorMessage = e.message;
      onChanged();
    } catch (_) {
      errorMessage = 'Não foi possível remover.';
      onChanged();
    } finally {
      submitting = false;
      onChanged();
    }
  }

  // ── Navegação com proteção de descarte (M3) ─────────────────────────────

  /// Sair da rota com confirmação de descarte quando há alterações não
  /// salvas — idêntico nas duas telas.
  Future<void> handleBack(
    BuildContext context, {
    required bool Function() isMounted,
  }) async {
    if (hasChanges && !submitting && !saved) {
      final discard = await showKicksterConfirm(
        context: context,
        title: 'Descartar alterações?',
        content: 'As alterações não salvas serão perdidas.',
        confirmLabel: 'Descartar',
        danger: true,
      );
      if (discard != true) return;
      if (!isMounted()) return;
      saved = true;
      onChanged();
    }
    if (!isMounted()) return;
    // O guard `isMounted()` acima equivale ao `if (!mounted) return;`
    // do State original — o analyzer não reconhece a função injetada.
    // ignore: use_build_context_synchronously
    goBack(context);
  }

  void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/competitions');
    }
  }

  /// Libera os 7 controllers (remove listeners + dispose).
  void dispose() {
    for (final c in [
      name,
      description,
      organizationId,
      startDate,
      endDate,
      conferenceName,
      divisionName,
    ]) {
      c.dispose();
    }
  }
}