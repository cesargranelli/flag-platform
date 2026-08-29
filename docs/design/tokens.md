# Flag Platform — Design Tokens

Fonte da verdade visual para os apps (Flutter). Reflete `frontend/packages/core/lib/src/theme/app_colors.dart` e `app_theme.dart`. O agente de UX deve basear propostas nestes tokens — qualquer mudança de token deve ser proposta aqui e refletida no `core`.

## Referência Figma (UI Kit Kickster)

- **Arquivo**: [Kickster — Live Score & News Sport (Community)](https://www.figma.com/design/bXGRAtra3DkMAPGKLLLaCQ/Kickster---Live-Score---News-Sport-Apps-UI-Kits--Community-?node-id=65-400)
- Referência completa em `docs/design/kickster-reference.md` (issue #431).
- Usar como referência visual de componentes ao avaliar/propor layouts (ex.: calendário, inputs, chips).

## Cores

Marca única adotada (2026-08-29, issue #431): paleta do UI Kit **Kickster** (primário azul royal, fundo claro), mapeada para os tokens semânticos atuais. Substitui a paleta Shifty (laranja).

| Token | Valor | Uso |
|---|---|---|
| `color.primary` | `#083879` | Marca, AppBar, botões principais, destaque (azul royal) |
| `color.secondary` | `#17153B` | Elementos secundários, azul-escuro |
| `color.accent` | `#0A4A9E` | Alertas/destaques pontuais (azul mais claro) |
| `color.success` | `#00C566` | Sucesso, status positivos, pontos |
| `color.warning` | `#FACC15` | Avisos, alertas — **conteúdo (texto/ícone) deve ser escuro** (`#171725`), nunca branco |
| `color.danger` | `#E53935` | Erro, cancelamento, fim de partida |
| `color.black` | `#111111` | Preto (bordas, checado) |
| `color.disabled` | `#9CA4AB` | Texto/fundo de elementos desabilitados |
| `color.gray.fill` | `#ECF1F6` | Preenchimentos neutros (checkbox não checado) |
| `color.background` | `#FEFEFE` | Fundo de telas |
| `color.surface` | `#FFFFFF` | Cards, inputs, superfícies elevadas |
| `color.text.primary` | `#171725` | Texto principal |
| `color.text.secondary` | `#66707A` | Legendas, metadados, placeholders (4.6:1 sobre surface — AA) |
| `color.text.muted` | `rgba(0,0,0,.6)` | Subtítulos de tela e rodapé (issue #269) |
| `color.gray.g100` | `#78828A` | Labels curtas em caixa alta (divisor "OU") |
| `color.field.border` | `#DADADA` | Borda de repouso dos campos do kit (inputs/dropdowns) |
| `color.surface.muted` | `#F6F8FE` | BG secundário — fundo azulado de cards/áreas |

### Semântica esportiva
- **Ao vivo / sucesso**: verde (`#00C566` / `#24D173`)
- **Fim de partida / negativo**: vermelho (`#E53935`)

## Tipografia

Família da marca: **Plus Jakarta Sans**, aplicada via pacote `google_fonts` (fetch em runtime com cache HTTP; offline cai na fonte padrão da plataforma, sem quebrar o app). Escala do Kickster (letter-spacing = tamanho × 0.005):

| Token | Tamanho | Peso | Uso |
|---|---|---|---|
| `type.display` | 48 / 56 | bold | H1 — destaques |
| `type.headline.md` | 40 / 48 | bold | H2 — títulos de tela |
| `type.headline.sm` | 32 / 40 | bold | H3 — títulos de seção |
| `type.title.lg` | 24 / 32 | bold | H4 — cabeçalhos |
| `type.title.md` | 20 / 28 | semibold | H5 — subtítulos / cartões |
| `type.title.sm` | 18 / 26 | semibold | H6 — rótulos |
| `type.body` | 16 / 24 | regular | Body Large |
| `type.body.md` | 14 / 22 | regular | Body Medium — corpo |
| `type.body.sm` | 12 / 20 | regular | Body Small — corpo secundário |

### Estilos nomeados (`AppTextStyles`)

Constantes em `frontend/packages/core/lib/src/theme/app_text_styles.dart`, com letter-spacing da spec do Figma. A família é herdada do tema; a cor pode ser ajustada no ponto de uso via `copyWith`.

| Token | Tamanho/Linha | Peso | Letter-spacing | Cor padrão | Uso |
|---|---|---|---|---|---|
| `headline1` | 48 / 56 | w700 | 0.24 | `text.primary` | H1 — títulos de destaque |
| `subtitle` | 20 / 28 | w500 | 0.10 | `text.muted` | Subtítulo de tela |
| `labelMedium` | 14 / 22 | w500 | 0.07 | parametrizável | Links e rótulos de checkbox |
| `paragraph` | 14 / 22 | w400 | 0.07 | `text.primary` | Parágrafo |
| `fieldLabel` | 12 / 20 | w400 | 0.06 | `text.primary` @40% | Rótulo flutuante de input |
| `overlineLabel` | 12 / 20 | w700 | +1 (uppercase) | `gray.g100` | Overline — divisor "OU" / seções de drawer |
| `buttonText` | 14 / 22 | w700 | 0.07 | branco | Texto de botão primário |
| `footerLink` | 13 / 17 | w500 | 0.07 | `text.muted` | Link/texto de rodapé |

## Espaçamento

Escala: `4, 8, 12, 16, 24, 32`. Uso típico: padding de tela `16`, espaçamento entre cards `12`, entre grupos `24`.

## Formas e elevação

| Token | Valor |
|---|---|---|
| `radius.button` | 16 |
| `radius.input` | 16 |
| `radius.card` | 16 |
| `radius.chip` | 10 |
| `radius.status` | 30 |
| `radius.checkbox` | 2 |
| `elevation.card` | 1 |

## Componentes (padrões do Kickster)

- **Inputs** (`InputDecorationTheme`): preenchidos (`surface`), `OutlineInputBorder` raio 16, conteúdo vertical ~64px, **rótulo sempre visível** (12/16 ls−0.2 @40% — `fieldLabel`); estados **Normal / Focado / Disabled / Error** (borda `text.primary` 1px Main/Dark / `primary` / `disabled` / `danger`)
- **Botões** (`FilledButton`/`ElevatedButton`/`OutlinedButton`): altura mínima **56px**, raio 16; variantes **Main** (fundo `primary`), **Disable** (fundo `disabled`, texto `textPrimary`), **Ghost** (borda `primary`)
- **Chip**: raio 10; selecionado com fundo `primary`; não selecionado com borda `black`
- **SelectableCard** (`widgets/selectable_card.dart`, padrão final #300): card de seleção única (comportamento de rádio por grupo) — interação IDÊNTICA aos cards de lista: `Card` (raio 16, elevação 1, clipBehavior) + `InkWell` com tinta PADRÃO do tema; proibido hover/splash/foco customizados (causam cintilação no web). Padding interno 16, **altura mín. 120px (único — substitui os 96px padrão e os 72px compactos)**, grid gap 12. Layout vertical: **ícone (28px) acima do rótulo acima da descrição**, com `maxLines: 1` (ellipsis) na descrição, e conteúdo **centralizado verticalmente** (`mainAxisAlignment.center`) para o card "só rótulo" preencher os 120px sem espaço vazio no rodapé. Cards sem descrição (ex.: Gênero) mantêm a **simetria com um ícone representativo** (`Icons.male`/`Icons.female`/`Icons.transgender`). Seleção por `Container` interno: não selecionado = card `surface` padrão · **selecionado** = fundo `primary` SÓLIDO + label/descrição/ícone BRANCOS + badge invertido no canto superior direito (círculo branco 24px, ícone `primary`) (#294) · desabilitado 55% de opacidade. Tipografia: label `titleSmall` (14/24 w700), descrição 13/17 w500
- **SelectableChip** (#290/#292/#300): variação compacta (raio 10) para grupos com muitas opções (ex.: faixa etária), gap 8 em wrap; altura ~34px (padding 16×8), peso fixo w500, tipografia 13/17 (`footerLink`). **Padrão SEM bordas e SEM overrides de splash** — `InkWell` padrão do tema sobre `AnimatedContainer` (120ms): não selecionado = fundo `gray.fill` + texto `textPrimary` · **selecionado** = fundo `primary` + texto **BRANCO**
- **Regra de conteúdo sobre primário (#294/#431)**: conteúdo (**texto e ícone**) sobre preenchimento `primary` (#083879) usa **BRANCO** — contraste branco/azul royal ≈ 7,7:1 (WCAG AA ok). Sobre `success` (#00C566) também usa branco, aceito conscientemente para estados de seleção (≈ 2,3:1, abaixo de AA). **`warning` (#FACC15) nunca recebe conteúdo branco** — usar texto/ícone escuro (`text.primary` #171725).
- **Navegação por sessões (#323/#332) — indicador de passos `AppStepIndicator` (`flag_core`)**: círculos de 28px (`radius 14`), um por etapa, distribuídos em `Row`/`Expanded` pela largura, com rótulo abaixo (14px, negrito se ativo) e toque via `InkWell` padrão (#300). Dois modos:
  - **Modo números (cadastro/wizard — `icons` nulo)**: **concluída** = círculo `success` + check **branco**; **atual** = círculo `primary` + ponto **branco**; **pendente** = círculo `grayFill` + número ordinal `textPrimary`
  - **Modo ícones (telas de detalhe — `icons` fornecido, `showDoneState: false`)**: cada círculo exibe o **ícone da sessão**; **apenas a etapa ativa** fica selecionada — o item inteiro recebe fundo `primary` (todo azul royal) com conteúdo (**ícone + rótulo**) **BRANCO**; as demais permanecem **"não selecionadas"** (círculo `grayFill` + ícone `textPrimary`, sem o verde de "concluído")
  Conteúdo **BRANCO** sobre `primary`/`success` (#294). Na tela de detalhe, tocar em uma etapa troca a sessão ativa exibida — a tela mostra **apenas** o conteúdo da sessão ativa. A variante em cards (`AppSessionNav`) permanece disponível no `flag_core` como alternativa.
- **Interação de cards/chips selecionáveis (#300)**: usar sempre `Card`/`InkWell`/tinta padrão do tema, como nos cards de listagem — NÃO implementar hover via `setState`/`MouseRegion` custom nem desabilitar splash com overlays próprios (flash branco e cintilação no web)
- **Checkbox**: 24px, raio 2; checado `primary`, não checado `gray.fill`
- **Card**: `surface`, raio 16, elevação 1
- **Card de conteúdo (`AppInfoCard`, `flag_core` — `widgets/app_info_card.dart`, #328)**: padrão dos cards de conteúdo das telas de detalhe. `Card` com `margin: EdgeInsets.zero`; `minHeight` padrão **144**; título `titleSmall` (14/24 w700) com **gap 12** para o conteúdo; linhas `AppInfoRow` (rótulo fixo **120px/13px `textSecondary`** + valor **14px**, padding bottom 8) e `AppInfoColorRow` (swatch 18×18 raio 4 + hex em maiúsculas). Largura via `AppLayout.detail` (720). Opcional `icon` (20px `primary`) ao lado do título.
- **AppBar**: fundo `primary`, texto branco, título centralizado
- **Estados**: `AppLoading` (carregando), `AppEmptyState` (vazio com ícone), `AppErrorState` (erro com "Tentar novamente")
- **Alvos de toque**: mín. 48px (ícones acionáveis); botões 56px

## Componentes Kickster (`flag_core` — issue #436)

Biblioteca de widgets no `frontend/packages/core/lib/src/widgets/` (prefixo `Kickster*`, exportados no barrel `flag_core.dart`). Todos usam apenas tokens (`AppColors.*`/`AppTheme`) — sem hex hardcoded.

| Widget | Arquivo | Uso |
|---|---|---|
| `KicksterCard` | `kickster_card.dart` | Card de módulo (home): raio **12**, fundo `surface`, elevação 1, `InkWell` padrão; ícone 28px `primary` em círculo 56px `primary`@10% + título (FittedBox) |
| `KicksterScoreCard` | `kickster_score_card.dart` | Card de jogo com placar (Live Match): confronto Time A × Time B, placar central em `headlineSmall`, badge de status (`GameStatus.label`) |
| `KicksterBadge` | `kickster_badge.dart` | Badge de status: fundo `color`@12%, texto/ícone na cor do badge, raio 10, `Semantics`; **`warning` → conteúdo escuro `textPrimary` (#294)** |
| `KicksterChip` | `kickster_chip.dart` | Chip selecionável (raio 10, ~34px compacto): não selecionado `grayFill`/`textPrimary`; selecionado `primary`/**branco**; `InkWell` padrão (#300) |
| `KicksterButton` | `kickster_button.dart` | Wrapper tipado dos botões do tema (variantes `primary`/`outline`/`text` — `FilledButton`/`OutlinedButton`/`TextButton`), com `icon?` e `loading?` |
| `KicksterInput` | `kickster_input.dart` | Wrapper de `TextFormField` sobre o `InputDecorationTheme` (raio 16, rótulo visível) — não sobrescreve bordas |
| `KicksterSectionTitle` | `kickster_section_title.dart` | Título de seção ("Ao vivo"/"Próximos"): `titleMedium` `textPrimary`, ícone `primary` opcional, `action?` à direita |
| `KicksterNavBar` | `kickster_nav_bar.dart` | Barra de navegação inferior mobile: `NavigationBar` com fundo `surface` e indicador `primary`@12% |

- **Mapeamento de status do `KicksterScoreCard`**: `inProgress` → `success` · `finished` → `danger` · `scheduled` → `textSecondary` · `cancelled` → `disabled`

## Layout responsivo

| Breakpoint | Comportamento |
|---|---|
| `< 960px` | Layout estreito (mobile): menus em lista, cards empilhados |
| `>= 960px` | Layout largo (desktop): `NavigationRail`, painéis em colunas |

### Larguras máximas (padrão web)

Em telas largas, o conteúdo é centralizado com largura máxima para preservar legibilidade (45–75 caracteres por linha) e hierarquia. Refletido em `frontend/packages/core/lib/src/layout/app_layout.dart` (widget `AppLayout`).

| Token | Valor | Uso |
|---|---|---|
| `layout.maxForm` | 600 | Formulários (wizard e CRUD) |
| `layout.maxDetail` | 720 | Telas de detalhe/leitura |
| `layout.maxContent` | 1200 | Listagens e conteúdo |

Wrappers: `AppLayout.form(child)`, `AppLayout.detail(child)`, `AppLayout.content(child)`.

## Acessibilidade (mínimo)

- Contraste de texto ≥ 4.5:1 (texto secundário sobre `surface` validado)
- Foco visível em todos os interativos
- Rótulos sempre visíveis em formulários
- Estados de erro no campo e mensagem clara
