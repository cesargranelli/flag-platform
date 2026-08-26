import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_screen.dart';
import '../widgets/selectable_card.dart';

/// Edição de campeonato (issue #287) — classe separada da criação.
///
/// Editável apenas em RASCUNHO. O status não é campo de formulário:
/// fica em uma faixa de estado acima do wizard com a ação "Publicar"
/// (único caminho de publicação, com confirmação).
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

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _organizationId;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;

  Modality? _modality;
  Gender? _gender;
  AgeGroup? _ageGroup;

  CompetitionStatus _status = CompetitionStatus.draft;
  int _step = 0;
  bool _submitting = false;
  bool _saved = false;
  bool _hasChanges = false;
  String? _errorMessage;

  /// Suprime dirty durante hidratação programática.
  bool _populating = false;

  /// Modo edição busca SEMPRE a competição completa por id: o objeto vindo
  /// da listagem (extra) é shape de resumo e não tem organizationId/datas.
  bool _appliedRemote = false;

  String? _modalityError;
  String? _categoryError;

  static const _titles = ['Campeonato', 'Modalidade', 'Categoria', 'Temporada'];

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

  void _applyCompetition(Competition competition) {
    _populating = true;
    _name.text = competition.name;
    _description.text = competition.description ?? '';
    _organizationId.text = competition.organizationId ?? '';
    _startDate.text = _formatDate(competition.startDate);
    _endDate.text = _formatDate(competition.endDate);
    _modality = competition.modality;
    _gender = competition.gender == null
        ? null
        : Gender.fromJson(competition.gender!);
    _ageGroup = competition.ageGroup == null
        ? null
        : AgeGroup.fromJson(competition.ageGroup!);
    _status = competition.status;
    _populating = false;
    _appliedRemote = true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _organizationId,
      _startDate,
      _endDate,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime? date) => date == null
      ? ''
      : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _selectModality(Modality value) {
    setState(() {
      _modality = value;
      _modalityError = null;
    });
    _markDirty();
  }

  void _selectGender(Gender value) {
    setState(() {
      _gender = value;
      _categoryError = null;
    });
    _markDirty();
  }

  void _selectAgeGroup(AgeGroup value) {
    setState(() {
      _ageGroup = value;
      _categoryError = null;
    });
    _markDirty();
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
      valid = false;
    }
    return valid;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < _titles.length - 1) {
      setState(() => _step += 1);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (!_validateStep()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(competitionApiProvider);
      final id = widget.competitionId!;
      // O status persistido é sempre o atual: publicação é uma ação
      // dedicada (_publish), não um campo do formulário.
      await api.update(
        id,
        organizationId: _organizationId.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        endDate: _endDate.text.isEmpty ? null : _endDate.text,
        status: _status,
        modality: _modality,
        gender: _gender?.toJson(),
        ageGroup: _ageGroup?.toJson(),
      );
      ref.invalidate(competitionsProvider);
      ref.invalidate(competitionProvider(id));

      _saved = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campeonato salvo com sucesso')),
        );
        context.go('/competitions/$id');
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o campeonato.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Publica o campeonato (DRAFT → PUBLISHED), ação irreversível com
  /// confirmação. Após publicar, retorna ao detalhe (edição fica travada).
  Future<void> _publish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publicar campeonato'),
        content: const Text(
          'Após publicar, o campeonato não poderá mais ser editado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(competitionApiProvider);
      final id = widget.competitionId!;
      await api.update(
        id,
        organizationId: _organizationId.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        startDate: _startDate.text.isEmpty ? null : _startDate.text,
        endDate: _endDate.text.isEmpty ? null : _endDate.text,
        status: CompetitionStatus.published,
        modality: _modality,
        gender: _gender?.toJson(),
        ageGroup: _ageGroup?.toJson(),
      );
      ref.invalidate(competitionsProvider);
      ref.invalidate(competitionProvider(id));
      _saved = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campeonato publicado')),
        );
        context.go('/competitions/$id');
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível publicar o campeonato.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Voltar: sessão anterior dentro do wizard; na primeira, sai da rota.
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
    if (!_appliedRemote) {
      final asyncComp = ref.watch(competitionProvider(widget.competitionId!));
      return asyncComp.when(
        loading: () => AppScreen(
          title: 'Editar campeonato',
          leading: AppBackButton(fallbackRoute: '/competitions'),
          body: const AppLoading(message: 'Carregando campeonato...'),
        ),
        error: (error, stackTrace) => AppScreen(
          title: 'Editar campeonato',
          leading: AppBackButton(fallbackRoute: '/competitions'),
          body: AppErrorState(
            message: 'Não foi possível carregar o campeonato',
            onRetry: () =>
                ref.invalidate(competitionProvider(widget.competitionId!)),
          ),
        ),
        data: (competition) {
          // Issue #261: sem permissão (criador/ADMIN), estado informativo.
          final user = ref.watch(authControllerProvider).state.user;
          if (!canEditCompetition(user, competition)) {
            return AppScreen(
              title: 'Editar campeonato',
              leading: AppBackButton(fallbackRoute: '/competitions'),
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
              leading: AppBackButton(fallbackRoute: '/competitions'),
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
          _applyCompetition(competition);
          return _buildEditable(context);
        },
      );
    }
    return _buildEditable(context);
  }

  Widget _buildEditable(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges || _submitting || _saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AppScreen(
        title: 'Editar campeonato',
        leading: BackButton(onPressed: _handleBack),
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
                  // Faixa de estado do status (issue #287): chip + Publicar.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        _statusChip(_status),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _submitting ? null : _publish,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          icon: const Icon(Icons.publish_outlined, size: 18),
                          label: const Text('Publicar'),
                        ),
                      ],
                    ),
                  ),
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
                          const SizedBox(height: 24),
                          _structureCard(context),
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
                    label: Text(
                      _step == _titles.length - 1 ? 'Salvar' : 'Continuar',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Issue #258: configuração de estrutura (conferências/divisões) apenas
  /// em edição, para quem pode editar e enquanto rascunho.
  Widget _structureCard(BuildContext context) {
    final user = ref.watch(authControllerProvider).state.user;
    final competition =
        ref.watch(competitionProvider(widget.competitionId!)).valueOrNull;
    final canConfigureStructure = canEditCompetition(user, competition);
    if (!canConfigureStructure) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estrutura do campeonato',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Configure conferências, divisões e associe clubes às divisões.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(selectedCompetitionProvider.notifier).state =
                    widget.competitionId!;
                context.push('/groupings');
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Configurar conferências e divisões'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(CompetitionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grayFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
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
    if (index > _step) {
      if (index > _step + 1) return;
      if (!_validateStep()) return;
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

  Widget _stepContent(BuildContext context) {
    switch (_step) {
      case 0:
        return _identityStep(context);
      case 1:
        return _modalityStep(context);
      case 2:
        return _categoryStep(context);
      default:
        return _seasonStep(context);
    }
  }

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
              key: ValueKey('edit-${_organizationId.text}'),
              initialValue: _organizationId.text.isEmpty
                  ? null
                  : _organizationId.text,
              decoration: const InputDecoration(
                labelText: 'Organização',
                border: OutlineInputBorder(),
              ),
              items: orgs
                  .map(
                    (o) =>
                        DropdownMenuItem(value: o.id, child: Text(o.tradeName)),
                  )
                  .toList(),
              onChanged: (value) {
                _organizationId.text = value ?? '';
                setState(() {});
              },
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

  Widget _modalityStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Modalidade'),
        const SizedBox(height: 4),
        const Text(
          'Formato de jogo do campeonato',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
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
                      onTap: () => _selectModality(modality),
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

  Widget _categoryStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('Gênero'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 24) / 3;
            return Row(
              children: [
                for (final gender in Gender.values) ...[
                  if (gender != Gender.values.first) const SizedBox(width: 12),
                  SizedBox(
                    width: cardWidth,
                    child: SelectableCard(
                      label: gender.label,
                      selected: _gender == gender,
                      onTap: () => _selectGender(gender),
                      minHeight: 72,
                    ),
                  ),
                ],
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
                onTap: () => _selectAgeGroup(ageGroup),
              ),
          ],
        ),
        if (_categoryError != null && _gender != null && _ageGroup == null)
          _groupError(_categoryError!),
      ],
    );
  }

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
      ],
    );
  }

  String _statusLabel(CompetitionStatus status) => switch (status) {
        CompetitionStatus.draft => 'Rascunho',
        CompetitionStatus.published => 'Publicado',
        CompetitionStatus.finished => 'Encerrado',
        CompetitionStatus.disabled => 'Desativado',
      };
}
