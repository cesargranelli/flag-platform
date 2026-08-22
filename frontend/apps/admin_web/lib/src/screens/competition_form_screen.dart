import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/competition_permissions.dart';
import '../providers/providers.dart';
import '../widgets/app_back_button.dart';

/// Formulário de criação/edição de campeonato.
class CompetitionFormScreen extends ConsumerStatefulWidget {
  const CompetitionFormScreen({
    super.key,
    this.competitionId,
    this.competition,
  });

  final String? competitionId;
  final Competition? competition;

  @override
  ConsumerState<CompetitionFormScreen> createState() =>
      _CompetitionFormScreenState();
}

class _CompetitionFormScreenState extends ConsumerState<CompetitionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _organizationId;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  Modality? _modality;
  String? _gender;
  String? _ageGroup;

  CompetitionStatus? _status;
  bool _submitting = false;
  String? _errorMessage;

  /// Modo edição busca SEMPRE a competição completa por id: o objeto vindo
  /// da listagem (extra) é shape de resumo e não tem organizationId/datas.
  bool _appliedRemote = false;

  bool get _isEditing => widget.competitionId != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _description = TextEditingController();
    _organizationId = TextEditingController();
    _startDate = TextEditingController();
    _endDate = TextEditingController();
    _modality = null;
    _gender = null;
    _ageGroup = null;
    _status = null;
  }

  /// Popula o formulário uma única vez com a competição carregada da API.
  void _applyCompetition(Competition competition) {
    _name.text = competition.name;
    _description.text = competition.description ?? '';
    _organizationId.text = competition.organizationId ?? '';
    _startDate.text = _formatDate(competition.startDate);
    _endDate.text = _formatDate(competition.endDate);
    _modality = competition.modality;
    _gender = competition.gender;
    _ageGroup = competition.ageGroup;
    _status = competition.status;
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

  /// Issue #257 (D): em modo CRIAÇÃO, quando o organizador possui exatamente
  /// 1 organização disponível, pré-seleciona-a automaticamente — elimina a
  /// dúvida central da história sem adicionar etapas ao fluxo.
  void _maybePreselectOrganization(List<Organization> orgs) {
    if (_isEditing || _organizationId.text.isNotEmpty || orgs.length != 1) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _organizationId.text.isNotEmpty) return;
      setState(() => _organizationId.text = orgs.single.id);
    });
  }


  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    // Issue #256: calendário do design system (spec Figma) no lugar do
    // showDatePicker padrão. Cancelamento continua retornando null.
    final picked = await showAppCalendarDialog(
      context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = _formatDate(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(competitionApiProvider);
      final orgId = _organizationId.text.trim();

      final id = widget.competitionId;
      if (id == null) {
        await api.create(
          organizationId: orgId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          startDate: _startDate.text.isEmpty ? null : _startDate.text,
          endDate: _endDate.text.isEmpty ? null : _endDate.text,
          status: _status,
          modality: _modality,
          gender: _gender,
          ageGroup: _ageGroup,
        );
      } else {
        await api.update(
          id,
          organizationId: orgId,
          name: _name.text.trim(),
          description: _description.text.trim(),
          startDate: _startDate.text.isEmpty ? null : _startDate.text,
          endDate: _endDate.text.isEmpty ? null : _endDate.text,
          status: _status,
          modality: _modality,
          gender: _gender,
          ageGroup: _ageGroup,
        );
        ref.invalidate(competitionProvider(id));
      }
      ref.invalidate(competitionsProvider);

      // Decisão do usuário: após salvar, voltar sempre para a LISTA.
      if (mounted) {
        context.go('/competitions');
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o campeonato.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizations = ref.watch(organizationsProvider);

    // Modo edição: carrega a competição completa antes de renderizar o form.
    if (_isEditing && !_appliedRemote) {
      final asyncComp = ref.watch(competitionProvider(widget.competitionId!));
      return asyncComp.when(
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text('Editar campeonato'),
            leading: AppBackButton(fallbackRoute: '/competitions'),
          ),
          body: const AppLoading(message: 'Carregando campeonato...'),
        ),
        error: (error, stackTrace) => Scaffold(
          appBar: AppBar(
            title: const Text('Editar campeonato'),
            leading: AppBackButton(fallbackRoute: '/competitions'),
          ),
          body: AppErrorState(
            message: 'Não foi possível carregar o campeonato',
            onRetry: () => ref.invalidate(
              competitionProvider(widget.competitionId!),
            ),
          ),
        ),
        data: (competition) {
          // Issue #261: proteção contra acesso direto pela URL — sem
          // permissão (criador/ADMIN), exibe estado informativo em vez
          // de renderizar o formulário.
          final user = ref.watch(authControllerProvider).state.user;
          if (!canEditCompetition(user, competition)) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Editar campeonato'),
                leading: AppBackButton(fallbackRoute: '/competitions'),
              ),
              body: const AppEmptyState(
                message:
                    'Você não tem permissão para editar este campeonato.',
                icon: Icons.lock_outline,
              ),
            );
          }
          _applyCompetition(competition);
          return _buildForm(context, organizations);
        },
      );
    }

    return _buildForm(context, organizations);
  }

  Widget _buildForm(
    BuildContext context,
    AsyncValue<List<Organization>> organizations,
  ) {
    // Issue #258: configuração de estrutura só aparece em modo EDIÇÃO e
    // para quem pode editar o campeonato. O form de criação NÃO oferece
    // configuração de conferências/divisões (critério da issue).
    final user = ref.watch(authControllerProvider).state.user;
    final loadedCompetition = _isEditing
        ? ref.watch(competitionProvider(widget.competitionId!)).valueOrNull
        : null;
    final canConfigureStructure =
        _isEditing && canEditCompetition(user, loadedCompetition);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar campeonato' : 'Novo campeonato'),
        leading: AppBackButton(fallbackRoute: '/competitions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppLayout.form(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                organizations.when(
                  // Issue #257 (M1): durante o carregamento o campo permanece
                  // visível (desabilitado, com hint) — sem o salto de layout
                  // causado pela substituição por LinearProgressIndicator.
                  loading: () => DropdownButtonFormField<String>(
                    items: const <DropdownMenuItem<String>>[],
                    onChanged: null,
                    decoration: const InputDecoration(
                      labelText: 'Organização',
                      hintText: 'Carregando organizações…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  // Issue #257 (A1): falha de carga ganha ação de recuperação
                  // (retry), mesmo padrão do venue_form_screen.
                  error: (e, s) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                          onPressed: () =>
                              ref.invalidate(organizationsProvider),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                  data: (orgs) {
                    _maybePreselectOrganization(orgs);
                    if (orgs.isEmpty) {
                      // Issue #257: sem organizações o cadastro não pode ser
                      // concluído — mensagem orientadora sem travar o layout.
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.5),
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
                      // Issue #257 (D): chave derivada da seleção — o valor
                      // definido fora do dropdown (pré-seleção automática)
                      // precisa recriar o FormField porque initialValue só é
                      // lido na criação do estado.
                      key: ValueKey(
                        '${_isEditing ? 'edit' : 'create'}-${_organizationId.text}',
                      ),
                      initialValue: _organizationId.text.isEmpty
                          ? null
                          : _organizationId.text,
                      decoration: const InputDecoration(
                        labelText: 'Organização',
                        border: OutlineInputBorder(),
                      ),
                      items: orgs
                          .map(
                            (o) => DropdownMenuItem(
                              value: o.id,
                              child: Text(o.tradeName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _organizationId.text = value ?? ''),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<CompetitionStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: CompetitionStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(_statusLabel(s)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _status = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Modality>(
                  initialValue: _modality,
                  decoration: const InputDecoration(
                    labelText: 'Modalidade',
                    border: OutlineInputBorder(),
                  ),
                  items: Modality.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _modality = value),
                  validator: (value) =>
                      value == null ? 'Selecione a modalidade' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gênero',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Feminino')),
                    DropdownMenuItem(value: 'MIXED', child: Text('Misto')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Selecione o gênero'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _ageGroup,
                  decoration: const InputDecoration(
                    labelText: 'Faixa etária',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SUB11', child: Text('Sub-11')),
                    DropdownMenuItem(value: 'SUB13', child: Text('Sub-13')),
                    DropdownMenuItem(value: 'SUB14', child: Text('Sub-14')),
                    DropdownMenuItem(value: 'SUB15', child: Text('Sub-15')),
                    DropdownMenuItem(value: 'SUB17', child: Text('Sub-17')),
                    DropdownMenuItem(value: 'SUB20', child: Text('Sub-20')),
                    DropdownMenuItem(value: 'ADULT', child: Text('Adulto')),
                    DropdownMenuItem(value: 'MASTER', child: Text('Master')),
                    DropdownMenuItem(value: 'OPEN', child: Text('Livre')),
                  ],
                  onChanged: (value) => setState(() => _ageGroup = value),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Selecione a faixa etária'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDate,
                        readOnly: true,
                        onTap: () => _pickDate(_startDate),
                        decoration: const InputDecoration(
                          labelText: 'Início',
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
                        onTap: () => _pickDate(_endDate),
                        decoration: const InputDecoration(
                          labelText: 'Fim',
                          suffixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (canConfigureStructure) ...[
                  const SizedBox(height: 24),
                  Card(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure conferências, divisões e associe clubes '
                            'às divisões.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(selectedCompetitionProvider.notifier)
                                  .state = widget.competitionId!;
                              context.push('/groupings');
                            },
                            icon: const Icon(Icons.settings_outlined),
                            label: const Text(
                              'Configurar conferências e divisões',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _save,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(CompetitionStatus status) => switch (status) {
    CompetitionStatus.draft => 'Rascunho',
    CompetitionStatus.published => 'Publicado',
    CompetitionStatus.finished => 'Encerrado',
    CompetitionStatus.disabled => 'Desativado',
  };
}
