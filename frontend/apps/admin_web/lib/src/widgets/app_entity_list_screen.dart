import 'package:flag_core/flag_core.dart';
import 'package:flutter/material.dart';

/// Boilerplate de listagem em grid das telas do Admin Web (issue #459).
///
/// Encapsula o padrão repetido em ~9 telas de listagem:
/// - toolbar: contagem + [toolbarLeading] + `Spacer` + [toolbarTrailing] +
///   [KicksterSearchField] (debounce nativo do campo, não duplicado);
/// - filtro local por query (trim + lowercase, via [filter]);
/// - empty de busca ([AppEmptyState] com `Icons.search_off`);
/// - grid responsivo: [LayoutBuilder] → [GridView.builder] com `shrinkWrap` **desativado**,
///   `AlwaysScrollableScrollPhysics` e `cacheExtent` configurado para renderizar apenas
///   itens visíveis (lazy grid). A altura de cada célula é definida por
///   [mainAxisExtent].
///
/// O widget retorna um `Column` pensado para ser usado DENTRO do body da
/// tela — o body continua com seus próprios actions e `provider.when`
/// (loading/error/empty primário do módulo).
///
/// Contagem:
/// - Com [countLabel] (ex.: `'atletas'`): sem busca mostra
///   `"N atletas"` (usa [countLabelSingular] quando `items.length == 1`);
///   com busca mostra `"N resultado(s)"`.
/// - Sem [countLabel] (null): sem busca mostra `"X de Y"` — para listas
///   com filtros permanentes aplicados dentro de [filter] (ex.: organizações
///   por tipo); com busca mostra `"N resultado(s)"`.
class AppEntityListScreen<T> extends StatefulWidget {
  const AppEntityListScreen({
    super.key,
    required this.items,
    required this.cardBuilder,
    required this.searchField,
    required this.filter,
    this.countLabel,
    this.countLabelSingular,
    this.emptyMessage = 'Nenhum registro encontrado',
    this.mainAxisExtent = 96,
    this.minColumns = 1,
    this.maxColumns = 2,
    this.toolbarLeading,
    this.toolbarTrailing,
    this.searchWidth = 280,
    this.gridPadding = EdgeInsets.zero,
  });

  /// Lista já resolvida (data do provider).
  final List<T> items;

  /// Constrói o card de cada item do grid.
  final Widget Function(T item) cardBuilder;

  /// Controller do campo de busca (criado/descartado pela tela).
  final TextEditingController searchField;

  /// Filtro local: recebe a lista completa e a query já normalizada
  /// (trim + lowercase); retorna a lista filtrada.
  final List<T> Function(List<T> items, String query) filter;

  /// Rótulo plural da contagem sem busca (ex.: `'atletas'` → "3 atletas").
  /// Quando null, a contagem vira "X de Y" (filtros permanentes).
  final String? countLabel;

  /// Rótulo singular usado quando `items.length == 1` (ex.: `'atleta'`).
  final String? countLabelSingular;

  /// Mensagem do empty de busca.
  final String emptyMessage;

  /// Altura fixa de cada célula do grid.
  final double mainAxisExtent;

  /// Colunas em telas estreitas (< 600px).
  final int minColumns;

  /// Colunas em telas largas (>= 600px).
  final int maxColumns;

  /// Widget extra antes do `Spacer` (filtros/atalhos à esquerda, ex.:
  /// organizações com filtro por tipo e desativadas).
  final Widget? toolbarLeading;

  /// Widget extra depois do `Spacer`, antes do campo de busca (ex.:
  /// campeonatos com o toggle de desativados).
  final Widget? toolbarTrailing;

  /// Largura do campo de busca.
  final double searchWidth;

  /// Padding interno do grid.
  final EdgeInsetsGeometry gridPadding;

  @override
  State<AppEntityListScreen<T>> createState() =>
      _AppEntityListScreenState<T>();
}

class _AppEntityListScreenState<T> extends State<AppEntityListScreen<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = widget.filter(widget.items, query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar (contagem + leading + trailing + busca) fica fixa no topo.
        Row(
          children: [
            _countText(filtered.length, query.isNotEmpty),
            if (widget.toolbarLeading != null) widget.toolbarLeading!,
            const Spacer(),
            if (widget.toolbarTrailing != null) widget.toolbarTrailing!,
            SizedBox(
              width: widget.searchWidth,
              child: KicksterSearchField(
                controller: widget.searchField,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Grid em altura finita (Expanded) → virtualização REAL. O widget é
        // usado dentro de um body com `scrollable:false` no AppScreen, que
        // fornece altura finita (Expanded) ao grid.
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  message: widget.emptyMessage,
                  icon: Icons.search_off,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600
                        ? widget.maxColumns
                        : widget.minColumns;
                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      cacheExtent: 100,
                      padding: widget.gridPadding,
                      itemCount: filtered.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: widget.mainAxisExtent,
                      ),
                      itemBuilder: (context, index) =>
                          widget.cardBuilder(filtered[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _countText(int filteredCount, bool searching) {
    final String text;
    if (searching) {
      text =
          '$filteredCount ${filteredCount == 1 ? 'resultado' : 'resultados'}';
    } else if (widget.countLabel == null) {
      // Modo "X de Y": filtros permanentes (ex.: organizações por tipo).
      text = '$filteredCount de ${widget.items.length}';
    } else {
      final label = widget.items.length == 1 &&
              widget.countLabelSingular != null
          ? widget.countLabelSingular!
          : widget.countLabel!;
      text = '${widget.items.length} $label';
    }
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    );
  }
}