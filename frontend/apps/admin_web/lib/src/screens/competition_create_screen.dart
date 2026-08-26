import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen.dart';
import '../widgets/selectable_card.dart';

/// Wizard de CRIAÇÃO de campeonato em 6 sessões (issues #287/#304).
///
/// Sessões 1–4 montam o cadastro; o botão "Criar rascunho" grava o
/// campeonato (sempre RASCUNHO) e habilita as sessões de estrutura
/// (Conferências → Agrupamento: Divisões ou Grupos), ambas com opção de
/// declínio — o fluxo nunca trava.
class CompetitionCreateScreen extends ConsumerStatefulWidget {
  const CompetitionCreateScreen({super.key});

  @override
  ConsumerState<CompetitionCreateScreen> createState() =>
      _CompetitionCreateScreenState();
}

class _CompetitionCreateScreenState
    extends ConsumerState<CompetitionCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _organizationId;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  final _conferenceName = TextEditingController();
  final _divisionName = TextEditingController();

  Modality? _modality;
  Gender? _gender;
  AgeGroup? _ageGroup;

  /// Campeonato recém-criado — alimenta as sessões de estrutura (#304).
  Competition? _created;

  bool _declinedConferences = false;
  bool _declinedStructure = false;
  GroupingType? _groupingChoice;

  /// Conferência selecionada para associar a nova divisão/grupo (#338).
  String? _conferenceId;

  int _step = 0;
  bool _submitting = false;
  bool _saved = false;
  bool _hasChanges = false;

  bool _populating = false;

  String? _modalityError;
  String? _categoryError;
  String? _errorMessage;

  static const _titles = [
    'Campeonato',
    'Modalidade',
    'Categoria',
    'Temporada',
    'Conferências',
    'Agrupamento',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _description = TextEditingController();
    _organizationId = TextEditingController();
    _startDate = TextEditingController();
    _endDate = TextEditingController();

    for (final controller in [
      _name,
      _description,
      _organizationId,
      _startDate,
      _endDate,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_populating || _saved || _hasChanges) return;
    setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _organizationId,
      _startDate,
      _endDate,
      _conferenceName,
      _divisionName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime? date) => date == null
      ? ''
      : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Issue #257 (D): com exatamente 1 organização disponível, pré-seleciona.
  void _maybePreselectOrganization(List<Organization> orgs) {
    if (_organizationId.text.isNotEmpty || orgs.length != 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _organizationId.text.isNotEmpty) return;
      setState(() {
        _populating = true;
        _organizationId.text = orgs.single.id;
        _populating = false;
      });
    });
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    DateTime? minDate,
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
    if (picked != null && mounted) {
      controller.text = _formatDate(picked);
    }
  }

  DateTime? get _parsedStartDate => DateTime.tryParse(_startDate.text.trim());

  bool _validateStep() {
    var valid = true;
    if (_step == 0) {
      valid = _formKey.currentState!.validate();
    } else if (_step == 1 && _modality == null) {
      setState(() => _modalityError = 'Selecione a modalidade');
      valid = false;
    } else if (_step == 2 && (_gender == null || _ageGroup == null)) {
      setState(() => _categoryError =
          _gender == null ? 'Selecione o gênero' : 'Selecione a faixa etária');
      valid = false;
    }
    return valid;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < _titles.length - 1) {
      // Sessão Temporada cria o rascunho antes das sessões de estrutura.
      if (_step == 3) {
        _createDraft();
        return;
      }
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  String get _draftLabel =>
      _step == 3 ? 'Criar rascunho' : (_step == 5 ? 'Concluir' : 'Continuar');

  /// Cria o campeonato em RASCUNHO e avança para a estrutura (#304).
  ///
  /// [targetStep] permite navegar direto à etapa desejada ao avançar pelo
  /// indicador (ex.: Agrupamento) — senão o rascunho não é criado e os botões
  /// "Adicionar" da estrutura ficam desabilitados (#338).
  Future<void> _createDraft({int? targetStep}) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(competitionApiProvider);
      final created = await api.create(
        organizationId: _organizationId.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        endDate: _endDate.text.isEmpty ? null : _endDate.text,
        modality: _modality,
        gender: _gender?.toJson(),
        ageGroup: _ageGroup?.toJson(),
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
        _step = targetStep ?? _step + 1;
      });
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível criar o campeonato.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Persiste a escolha de agrupamento (quando houver) e vai ao detalhe.
  Future<void> _finish() async {
    final created = _created!;
    final needsUpdate =
        !_declinedStructure && _groupingChoice != created.groupingType;

    if (needsUpdate) {
      setState(() {
        _submitting = true;
        _errorMessage = null;
      });
      try {
        final api = ref.read(competitionApiProvider);
        final updated = await api.update(
          created.id,
          organizationId: created.organizationId!,
          name: created.name,
          description: created.description,
          startDate: _formatDate(created.startDate),
          endDate: _formatDate(created.endDate),
          status: created.status,
          modality: created.modality,
          gender: created.gender,
          ageGroup: created.ageGroup,
          groupingType: _groupingChoice,
        );
        ref.invalidate(competitionProvider(created.id));
        _created = updated;
      } on RepositoryException catch (e) {
        setState(() => _errorMessage = e.message);
        return;
      } catch (_) {
        setState(
          () => _errorMessage =
              'Não foi possível salvar o tipo de agrupamento.',
        );
        return;
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

    _saved = true;
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

  Future<void> _addConference() async {
    final name = _conferenceName.text.trim();
    if (name.isEmpty || _created == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(conferenceApiProvider).create(
            competitionId: _created!.id,
            name: name,
          );
      _conferenceName.clear();
      ref.invalidate(conferencesProvider(_created!.id));
      _markDirty();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível adicionar.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _addDivision() async {
    final name = _divisionName.text.trim();
    if (name.isEmpty ||
        _created == null ||
        _groupingChoice == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(divisionApiProvider).create(
            competitionId: _created!.id,
            name: name,
            conferenceId: _conferenceId,
          );
      _divisionName.clear();
      ref.invalidate(divisionsProvider(_created!.id));
      _markDirty();
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível adicionar.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Voltar: navega para a sessão anterior quando dentro do wizard;
  /// na primeira sessão, sai da rota com proteção de descarte (M3).
  Future<void> _handleBack() async {
    if (_step > 0) {
      setState(() {
        _step -= 1;
        _modalityError = null;
        _categoryError = null;
      });
      return;
    }
    if (_hasChanges && !_submitting && !_saved) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text('As alterações não salvas serão perdidas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (discard != true) return;
      if (!mounted) return;
      setState(() => _saved = true);
    }
    if (!mounted) return;
    _goBack();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/competitions');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _submitting || _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppScreen(
        title: 'Novo campeonato',
        leading: AppBackButton(fallbackRoute: '/competitions'),
        body: _buildWizard(context),
      ),
    );
  }

  Widget _buildWizard(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: AppLayout.form(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: AppStepIndicator(
                      titles: _titles,
                      currentStep: _step,
                      onStepTap: _handleStepTap,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Etapa ${_step + 1} de ${_titles.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_errorMessage != null)
                            _errorBanner(_errorMessage!),
                          _stepContent(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppLayout.form(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _handleBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(120, 56),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
                    label: Text(_step == 0 ? 'Cancelar' : 'Voltar'),
                  ),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _next,
                    icon: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: Text(_draftLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  /// Tocar em uma etapa do indicador: avança apenas sequencialmente (com
  /// validação da etapa atual) e volta livremente (#323).
  void _handleStepTap(int index) {
    if (index == _step) return;
    // Avanço apenas sequencial (com validação); voltar é livre.
    if (index > _step) {
      if (index > _step + 1) return;
      if (!_validateStep()) return;
    }
    // Da Temporada (3) para as sessões de estrutura, o rascunho é criado antes
    // — senão os campos/botões "Adicionar" da estrutura ficam desabilitados.
    if (_step == 3 && _created == null) {
      _createDraft(targetStep: index);
      return;
    }
    setState(() => _step = index);
  }

  Widget _groupLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _groupError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.danger),
      ),
    );
  }

  Widget _hint(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    );
  }

  Widget _stepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _identityStep(context);
      case 1:
        return _modalityStep(context);
      case 2:
        return _categoryStep(context);
      case 3:
        return _seasonStep(context);
      case 4:
        return _conferencesStep(context);
      default:
        return _structureStep(context);
    }
  }

  // Sessão 1 — Campeonato: organização, nome e descrição.
  Widget _identityStep(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        organizations.when(
          loading: () => DropdownButtonFormField<String>(
            items: const <DropdownMenuItem<String>>[],
            onChanged: null,
            decoration: const InputDecoration(
              labelText: 'Organização',
              hintText: 'Carregando organizações…',
              border: OutlineInputBorder(),
            ),
          ),
          error: (e, s) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Erro ao carregar organizações',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ref.invalidate(organizationsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
          data: (orgs) {
            _maybePreselectOrganization(orgs);
            if (orgs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhuma organização disponível',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }
            return DropdownButtonFormField<String>(
              key: ValueKey('create-${_organizationId.text}'),
              initialValue: _organizationId.text.isEmpty
                  ? null
                  : _organizationId.text,
              decoration: InputDecoration(
                labelText:
                    'Organização${orgs.length == 1 ? ' (pré-selecionada)' : ''}',
                border: const OutlineInputBorder(),
              ),
              items: orgs
                  .map(
                    (o) =>
                        DropdownMenuItem(value: o.id, child: Text(o.tradeName)),
                  )
                  .toList(),
              onChanged: (value) => _organizationId.text = value ?? '',
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Selecione a organização'
                  : null,
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Nome',
            border: OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Informe o nome'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _description,
          decoration: const InputDecoration(
            labelText: 'Descrição',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  // Sessão 2 — Modalidade: cards 2x2.
  Widget _modalityStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Escolha a modalidade'),
        const SizedBox(height: 4),
        _hint('Formato de jogo do campeonato'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 480;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final modality in Modality.values)
                  SizedBox(
                    width: isWide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth,
                    child: SelectableCard(
                      label: modality.label,
                      description: _modalityDescription(modality),
                      icon: _modalityIcon(modality),
                      selected: _modality == modality,
                      onTap: () {
                        setState(() {
                          _modality = modality;
                          _modalityError = null;
                        });
                        _markDirty();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        if (_modalityError != null) _groupError(_modalityError!),
      ],
    );
  }

  String _modalityDescription(Modality modality) => switch (modality) {
        Modality.flag5x5 => 'Flag sem contato · 5 jogadores',
        Modality.flag8x8 => 'Flag sem contato · 8 jogadores',
        Modality.flag9x9 => 'Flag sem contato · 9 jogadores',
        Modality.fullPads11x11 => 'Tackle com proteção · 11 jogadores',
      };

  IconData _modalityIcon(Modality modality) =>
      modality == Modality.fullPads11x11
          ? Icons.shield_outlined
          : Icons.sports_football_outlined;

  /// Ícone representativo por gênero — mantém a simetria dos cards (#328).
  IconData _genderIcon(Gender gender) => switch (gender) {
        Gender.male => Icons.male,
        Gender.female => Icons.female,
        Gender.mixed => Icons.transgender,
      };

  // Sessão 3 — Categoria: gênero (cards) + faixa etária (chips).
  Widget _categoryStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Gênero'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 480;
            final cardWidth = isWide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final gender in Gender.values)
                  SizedBox(
                    width: cardWidth,
                    child: SelectableCard(
                      label: gender.label,
                      icon: _genderIcon(gender),
                      selected: _gender == gender,
                      onTap: () {
                        setState(() {
                          _gender = gender;
                          _categoryError = null;
                        });
                        _markDirty();
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        if (_categoryError != null && _gender == null)
          _groupError('Selecione o gênero'),
        const SizedBox(height: 20),
        _groupLabel('Faixa etária'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ageGroup in AgeGroup.values)
              SelectableChip(
                label: ageGroup.label,
                selected: _ageGroup == ageGroup,
                onTap: () {
                  setState(() {
                    _ageGroup = ageGroup;
                    _categoryError = null;
                  });
                  _markDirty();
                },
              ),
          ],
        ),
        if (_categoryError != null && _gender != null && _ageGroup == null)
          _groupError(_categoryError!),
      ],
    );
  }

  // Sessão 4 — Temporada: datas opcionais + resumo das escolhas.
  Widget _seasonStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _groupLabel('Período da temporada (opcional)'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _startDate,
                readOnly: true,
                onTap: () => _pickDate(_startDate),
                decoration: const InputDecoration(
                  labelText: 'Início (opcional)',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _endDate,
                readOnly: true,
                onTap: () => _pickDate(_endDate, minDate: _parsedStartDate),
                decoration: const InputDecoration(
                  labelText: 'Fim (opcional)',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final start = _parsedStartDate;
                  final end = value == null || value.isEmpty
                      ? null
                      : DateTime.tryParse(value);
                  if (start != null && end != null && end.isBefore(start)) {
                    return 'Data final deve ser maior ou igual à data inicial';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _groupLabel('Resumo'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _summaryChip(
              _name.text.trim().isEmpty ? 'Campeonato' : _name.text.trim(),
              Icons.emoji_events_outlined,
            ),
            if (_modality != null)
              _summaryChip(_modality!.label, Icons.sports_football_outlined),
            if (_gender != null)
              _summaryChip(_gender!.label, Icons.groups_outlined),
            if (_ageGroup != null)
              _summaryChip(_ageGroup!.label, Icons.cake_outlined),
          ],
        ),
        const SizedBox(height: 16),
        _hint(
          'Ao continuar, o campeonato é criado como rascunho e você poderá '
          'configurar conferências, divisões ou grupos nas próximas etapas.',
        ),
      ],
    );
  }

  // Sessão 5 — Conferências (#304): criar/listar, com declínio.
  Widget _conferencesStep(BuildContext context) {
    final conferences = _created == null
        ? const AsyncValue<List<Conference>>.data([])
        : ref.watch(conferencesProvider(_created!.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Conferências'),
        const SizedBox(height: 4),
        _hint(
          'Opcional. Use conferências para separar grandes blocos do '
          'campeonato (ex.: Conferência Norte/Sul).',
        ),
        const SizedBox(height: 12),
        if (_declinedConferences) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grayFill),
              color: AppColors.grayFill.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Este campeonato não usará conferências.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _declinedConferences = false),
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Usar conferências'),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _conferenceName,
                  enabled: _created != null,
                  decoration: const InputDecoration(
                    labelText: 'Nome da conferência',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addConference(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed:
                    _created == null || _submitting ? null : _addConference,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          conferences.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => const Text(
              'Não foi possível carregar as conferências.',
              style: TextStyle(color: AppColors.danger),
            ),
            data: (items) => items.isEmpty
                ? _hint('Nenhuma conferência adicionada ainda.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in items) _summaryChip(c.name, Icons.account_tree_outlined),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() {
              _declinedConferences = true;
              _markDirty();
            }),
            child: const Text('Este campeonato não usa conferências'),
          ),
        ],
      ],
    );
  }

  // Sessão 6 — Agrupamento (#304/#338): Divisões OU Grupos, com declínio.
  Widget _structureStep(BuildContext context) {
    final divisions = _created == null
        ? const AsyncValue<List<Division>>.data([])
        : ref.watch(divisionsProvider(_created!.id));
    final conferences = _created == null
        ? const AsyncValue<List<Conference>>.data([])
        : ref.watch(conferencesProvider(_created!.id));
    final conferenceItems = conferences.valueOrNull ?? const <Conference>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Como os clubes serão agrupados?'),
        const SizedBox(height: 4),
        _hint('Divisões e Grupos têm o mesmo funcionamento — muda apenas o nome.'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Row(
              children: [
                for (final type in GroupingType.values) ...[
                  if (type != GroupingType.values.first)
                    const SizedBox(width: 12),
                  SizedBox(
                    width: cardWidth,
                    child: SelectableCard(
                      label: type.label,
                      description: 'Agrupamento por ${type.label.toLowerCase()}',
                      icon: Icons.account_tree_outlined,
                      selected: _groupingChoice == type,
                      onTap: () => setState(() {
                        _groupingChoice = type;
                        _declinedStructure = false;
                        _markDirty();
                      }),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        if (_declinedStructure)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grayFill),
              color: AppColors.grayFill.withValues(alpha: 0.5),
            ),
            child: const Text(
              'Este campeonato não usará divisões nem grupos.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else if (_groupingChoice == null)
          _hint(
            'Selecione Divisões ou Grupos acima, ou declare que este '
            'campeonato não usará agrupamentos.',
          )
        else ...[
          if (conferenceItems.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              key: ValueKey('division-conf-${_conferenceId ?? ''}'),
              initialValue: _conferenceId ?? '',
              decoration: const InputDecoration(
                labelText: 'Conferência',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Sem conferência'),
                ),
                for (final c in conferenceItems)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (value) => setState(
                () => _conferenceId =
                    (value == null || value.isEmpty) ? null : value,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _divisionName,
                  enabled: _created != null,
                  decoration: InputDecoration(
                    labelText: 'Nome ($_groupingChoice)',
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addDivision(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed:
                    _created == null || _submitting ? null : _addDivision,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          divisions.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, s) => Text(
              'Não foi possível carregar as $_itemLabelLower.',
              style: const TextStyle(color: AppColors.danger),
            ),
            data: (items) => items.isEmpty
                ? _hint('Nenhum item adicionado ainda.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in items)
                        _summaryChip(d.name, Icons.folder_outlined),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() {
              _declinedStructure = true;
              _groupingChoice = null;
              _markDirty();
            }),
            child: const Text('Não usar divisões nem grupos'),
          ),
        ],
      ],
    );
  }

  String get _itemLabelLower =>
      _groupingChoice == GroupingType.groups ? 'grupos' : 'divisões';

  Widget _summaryChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
