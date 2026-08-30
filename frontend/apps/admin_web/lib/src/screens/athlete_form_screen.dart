import 'package:flag_api/flag_api.dart';
import 'package:flag_core/flag_core.dart';
import 'package:flag_domain/flag_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../widgets/app_screen.dart';
import '../widgets/selectable_card.dart';

/// Formulário de criação/edição de atleta.
class AthleteFormScreen extends ConsumerStatefulWidget {
  const AthleteFormScreen({super.key, this.athleteId, this.athlete});

  final String? athleteId;
  final Athlete? athlete;

  @override
  ConsumerState<AthleteFormScreen> createState() => _AthleteFormScreenState();
}

class _AthleteFormScreenState extends ConsumerState<AthleteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _cpf;
  late final TextEditingController _nickname;
  late final TextEditingController _number;
  late final TextEditingController _photoUrl;
  List<AthletePosition> _positions = [];
  bool _submitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.athleteId != null || widget.athlete != null;

  @override
  void initState() {
    super.initState();
    final athlete = widget.athlete;
    _name = TextEditingController(text: athlete?.name ?? '');
    _cpf = TextEditingController(text: athlete?.cpf ?? '');
    _nickname = TextEditingController(text: athlete?.nickname ?? '');
    _number = TextEditingController(text: athlete?.number?.toString() ?? '');
    _photoUrl = TextEditingController(text: athlete?.photoUrl ?? '');
    _positions = List.of(athlete?.positions ?? []);
  }

  @override
  void dispose() {
    for (final controller in [_name, _cpf, _nickname, _number, _photoUrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateCpf(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe o CPF';
    return DocumentUtils.isValidCpf(value) ? null : 'CPF inválido';
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim()) == null
        ? 'Informe um número válido'
        : null;
  }

  String? _validatePhotoUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    final valid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Informe uma URL válida (http/https)';
  }

  Map<String, dynamic> _body() => {
        'name': _name.text.trim(),
        'cpf': _cpf.text.trim().replaceAll(RegExp(r'\D'), ''),
        if (_nickname.text.trim().isNotEmpty) 'nickname': _nickname.text.trim(),
        'positions': _positions.map((p) => p.toJson()).toList(),
        if (int.tryParse(_number.text.trim()) != null)
          'number': int.parse(_number.text.trim()),
        if (_photoUrl.text.trim().isNotEmpty) 'photoUrl': _photoUrl.text.trim(),
      };

  /// Alterna a seleção de uma posição, respeitando o limite de 3 e evitando
  /// duplicatas.
  void _togglePosition(AthletePosition position) {
    setState(() {
      if (_positions.contains(position)) {
        _positions.remove(position);
      } else if (_positions.length < 3) {
        _positions.add(position);
      }
    });
  }

  /// Campo de posições: um conjunto de chips de seleção, limitado a 3
  /// posições, sem duplicatas. As opções não selecionadas são desabilitadas ao
  /// atingir o limite para deixar claro que não há mais vagas.
  Widget _positionsField() {
    final maxed = _positions.length >= 3;
    return InputDecorator(
      decoration: kicksterFieldDecoration(
        labelText: 'Posições',
        helperText: 'Selecione até 3 posições',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final position in AthletePosition.values)
                SelectableChip(
                  label: position.label,
                  selected: _positions.contains(position),
                  // Desabilitadas as opções livres quando o limite é atingido
                  // (#371/#290): sem bordas; selecionado = fundo `primary` +
                  // texto branco (padrão do projeto).
                  onTap: maxed && !_positions.contains(position)
                      ? null
                      : () => _togglePosition(position),
                ),
            ],
          ),
          if (maxed) ...[
            const SizedBox(height: 6),
            const Text(
              'Máximo de 3 posições atingido. Desmarque uma para alterar.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(athleteApiProvider);
      final id = widget.athleteId ?? widget.athlete?.id;
      if (id == null) {
        await api.create(_body());
      } else {
        await api.update(id, _body());
      }
      ref.invalidate(athletesProvider);
      if (mounted) {
        if (id != null) {
          // Volta para o detalhe recarregado (busca fresca via provider).
          ref.invalidate(athleteProvider(id));
          context.go('/athletes/$id');
        } else {
          context.pop();
        }
      }
    } on RepositoryException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Não foi possível salvar o atleta.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: _isEditing ? 'Editar atleta' : 'Novo atleta',
      breadcrumb: const [
        BreadcrumbItem('Início', route: '/'),
        BreadcrumbItem(AppStrings.athletes, route: '/athletes'),
        BreadcrumbItem('Formulário'),
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
                KicksterInput(
                  label: 'Nome',
                  controller: _name,
                  maxLength: 100,
                  validator: (value) =>
                      (value == null || value.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'CPF',
                  controller: _cpf,
                  keyboardType: TextInputType.number,
                  hintText: '000.000.000-00',
                  onChanged: (value) {
                    final masked = DocumentUtils.maskCpf(value);
                    if (masked != value) {
                      _cpf.value = TextEditingValue(
                        text: masked,
                        selection:
                            TextSelection.collapsed(offset: masked.length),
                      );
                    }
                  },
                  validator: _validateCpf,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Apelido',
                  controller: _nickname,
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                _positionsField(),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'Número da camisa',
                  controller: _number,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  validator: _validateNumber,
                ),
                const SizedBox(height: 12),
                KicksterInput(
                  label: 'URL da foto',
                  controller: _photoUrl,
                  keyboardType: TextInputType.url,
                  hintText: 'Ex.: https://...',
                  validator: _validatePhotoUrl,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 24),
                KicksterButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  loading: _submitting,
                  onPressed: _submitting ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}
