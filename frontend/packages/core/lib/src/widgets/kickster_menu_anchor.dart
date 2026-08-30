import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Item do [KicksterMenuAnchor].
///
/// - [onTap] não nulo: item clicável (linha 48px com `InkWell` — foco por
///   Tab, ativação via Enter e semântica de botão).
/// - [onTap] nulo com [enabled] `true`: item informativo (ex.: cabeçalho do
///   usuário) — visual normal, sem interação nem foco.
/// - [enabled] `false`: item desabilitado — visual atenuado (`Opacity(0.5)`),
///   sem foco/interação.
class KicksterMenuItem {
  const KicksterMenuItem({
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  /// Conteúdo do item (linha de 48px com padding horizontal 16).
  final Widget child;

  /// Ação ao selecionar o item. Nulo torna o item informativo.
  final VoidCallback? onTap;

  /// Habilita/desabilita o item (desabilitado: atenuado e sem interação).
  final bool enabled;
}

/// Âncora de menu no padrão Kickster (issue #467).
///
/// [trigger] é o conteúdo visual do botão que abre o menu; o próprio widget
/// envolve o trigger em `Semantics(button)` + `InkWell`, garantindo toque,
/// foco por Tab, ativação via Enter e rótulo semântico ([triggerLabel]) sem
/// código extra no chamador.
///
/// Ao abrir, posiciona um [OverlayEntry] logo abaixo do anchor
/// (`top: anchorBottom + 8`) com o estilo do kit: container único, raio 12,
/// fundo `surface`, borda `line` 1px, itens de 48px com divisores internos
/// (mesmo padrão do [KicksterMenuAnchor] no Admin Web e do dropdown).
///
/// **Teclado**: ao abrir, o foco vai para o primeiro item habilitado; ↑/↓
/// navegam entre os itens (wrap), Enter ativa (nativo do `InkWell`) e Esc
/// fecha. Fecha também ao tocar fora, ao selecionar um item e no `dispose`
/// (o foco volta ao trigger ao fechar).
class KicksterMenuAnchor extends StatefulWidget {
  const KicksterMenuAnchor({
    super.key,
    required this.trigger,
    required this.items,
    this.triggerLabel,
    this.width,
    this.maxHeight,
    this.onOpenChanged,
  });

  /// Conteúdo visual do botão que abre o menu.
  final Widget trigger;

  /// Itens do menu (cabeçalho informativo, ações, etc.).
  final List<KicksterMenuItem> items;

  /// Rótulo semântico do trigger (leitura por leitores de tela).
  final String? triggerLabel;

  /// Largura do menu aberto. `null` => `clamp(200, 300)` da largura do
  /// trigger.
  final double? width;

  /// Altura máxima do menu aberto. Quando definido, o conteúdo rola
  /// internamente ([SingleChildScrollView]) ao exceder. `null` = sem
  /// limite.
  final double? maxHeight;

  /// Notifica a abertura/fechamento do menu (`true` ao abrir, `false` ao
  /// fechar) — útil para o trigger refletir o estado aberto. `null` =
  /// sem notificação.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<KicksterMenuAnchor> createState() => _KicksterMenuAnchorState();
}

class _KicksterMenuAnchorState extends State<KicksterMenuAnchor> {
  final GlobalKey _triggerKey = GlobalKey();
  final FocusNode _triggerFocusNode = FocusNode(debugLabel: 'KicksterMenuAnchor');
  OverlayEntry? _overlayEntry;
  bool _menuOpen = false;

  void _toggleMenu() {
    if (_menuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final triggerContext = _triggerKey.currentContext;
    if (triggerContext == null) return;
    final renderBox = triggerContext.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _KicksterMenuOverlay(
        anchorOffset: offset,
        anchorWidth: size.width,
        anchorBottom: offset.dy + size.height,
        width: widget.width,
        maxHeight: widget.maxHeight,
        items: widget.items,
        onClose: _closeMenu,
        onSelect: (item) {
          _closeMenu();
          item.onTap?.call();
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _menuOpen = true);
    widget.onOpenChanged?.call(true);
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    // Devolve o foco ao trigger (UX de teclado após Esc/seleção).
    _triggerFocusNode.requestFocus();
    if (mounted) setState(() => _menuOpen = false);
    widget.onOpenChanged?.call(false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _triggerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.triggerLabel,
      child: InkWell(
        key: _triggerKey,
        focusNode: _triggerFocusNode,
        onTap: _toggleMenu,
        borderRadius: BorderRadius.circular(8),
        child: widget.trigger,
      ),
    );
  }
}

/// Overlay do menu aberto: container único segmentado sob o anchor (modelo
/// do kit) — raio 12, fundo `surface`, borda `line` e itens de 48px com
/// divisores internos. Também gerencia o teclado do menu (foco inicial,
/// ↑/↓/Enter/Esc) via [FocusScope].
class _KicksterMenuOverlay extends StatefulWidget {
  const _KicksterMenuOverlay({
    required this.anchorOffset,
    required this.anchorWidth,
    required this.anchorBottom,
    required this.width,
    required this.maxHeight,
    required this.items,
    required this.onClose,
    required this.onSelect,
  });

  final Offset anchorOffset;
  final double anchorWidth;
  final double anchorBottom;
  final double? width;
  final double? maxHeight;
  final List<KicksterMenuItem> items;
  final VoidCallback onClose;
  final ValueChanged<KicksterMenuItem> onSelect;

  @override
  State<_KicksterMenuOverlay> createState() => _KicksterMenuOverlayState();
}

class _KicksterMenuOverlayState extends State<_KicksterMenuOverlay> {
  final FocusScopeNode _scopeNode =
      FocusScopeNode(debugLabel: 'KicksterMenuAnchor menu');

  /// Nós de foco dos itens interativos (enabled && onTap != null), na ordem.
  final List<FocusNode> _itemNodes = [];

  /// Índice do item na lista completa -> índice em [_itemNodes].
  final Map<int, int> _nodeIndexForItem = {};

  /// Item interativo atualmente focado (índice em [_itemNodes]).
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      if (item.enabled && item.onTap != null) {
        _nodeIndexForItem[i] = _itemNodes.length;
        _itemNodes.add(FocusNode(debugLabel: 'KicksterMenuItem $i'));
      }
    }
    // Foco inicial: primeiro item habilitado (ou o próprio scope, para que
    // o Esc funcione mesmo sem itens interativos).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_itemNodes.isNotEmpty) {
        _itemNodes.first.requestFocus();
      } else {
        _scopeNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (final node in _itemNodes) {
      node.dispose();
    }
    _scopeNode.dispose();
    super.dispose();
  }

  /// Navegação por teclado do menu: Esc fecha; ↑/↓ movem o foco entre os
  /// itens interativos (Enter é ativado nativamente pelo `InkWell` focado).
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveFocus(int delta) {
    final count = _itemNodes.length;
    if (count == 0) return;
    var next = _activeIndex + delta;
    if (next < 0) next = count - 1;
    if (next >= count) next = 0;
    _itemNodes[next].requestFocus();
    _activeIndex = next;
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? widget.anchorWidth.clamp(200, 300);
    return SizedBox.expand(
      child: Stack(
        children: [
          // Tocar fora fecha.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onClose,
            ),
          ),
          // Menu posicionado abaixo do anchor.
          Positioned(
            left: widget.anchorOffset.dx,
            top: widget.anchorBottom + 8,
            width: width,
            child: FocusScope(
              node: _scopeNode,
              includeSemantics: false,
              onKeyEvent: _handleKeyEvent,
              child: Material(
                color: Colors.transparent,
                child: _withMaxHeight(
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.items.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.line,
                            ),
                          _buildItem(i, widget.items[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Aplica [KicksterMenuAnchor.maxHeight] ao menu: limita a altura e rola
  /// o conteúdo internamente quando ele excede. Sem `maxHeight` (nulo),
  /// devolve o child intacto.
  Widget _withMaxHeight(Widget child) {
    final maxHeight = widget.maxHeight;
    if (maxHeight == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(child: child),
    );
  }

  Widget _buildItem(int index, KicksterMenuItem item) {
    final interactive = item.enabled && item.onTap != null;

    final content = Ink(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 12,
          height: 20 / 12,
          fontWeight: FontWeight.w400,
          color: AppColors.black,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: item.child,
        ),
      ),
    );

    Widget result = content;
    if (interactive) {
      final nodeIndex = _nodeIndexForItem[index]!;
      result = InkWell(
        focusNode: _itemNodes[nodeIndex],
        onFocusChange: (hasFocus) {
          if (hasFocus) _activeIndex = nodeIndex;
        },
        onTap: () => widget.onSelect(item),
        child: content,
      );
    }

    if (!item.enabled) {
      result = Opacity(opacity: 0.5, child: result);
    }
    return result;
  }
}