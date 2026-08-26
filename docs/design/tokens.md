# Flag Platform — Design Tokens

Fonte da verdade visual para os apps (Flutter). Reflete `frontend/packages/core/lib/src/theme/app_colors.dart` e `app_theme.dart`. O agente de UX deve basear propostas nestes tokens — qualquer mudança de token deve ser proposta aqui e refletida no `core`.

## Referência Figma (UI Kit Shifty)

- **Arquivo**: [Shifty — House Service App (Community)](https://www.figma.com/design/MxhoZOwT1HrI1Zrm3Vdc7M/Shifty---House-Service-App--Community-?node-id=5-0&t=LdacgMtgKolC4XVk-0)
- Usar como referência visual de componentes ao avaliar/propor layouts (ex.: calendário, inputs, chips).

## Cores

Marca única adotada (2026-08-14): paleta do UI Kit **Shifty** (primário laranja, fundo claro), harmonizada com cores semânticas dos kits esportivos (live/fim).

| Token | Valor | Uso |
|---|---|---|
| `color.primary` | `#FD6B22` | Marca, AppBar, botões principais, destaque |
| `color.secondary` | `#F15223` | Elementos secundários, hover de primário |
| `color.accent` | `#FF6628` | Alertas/destaques pontuais |
| `color.success` | `#4FBF67` | Sucesso, status positivos, pontos |
| `color.warning` | `#FF6628` | Avisos, alertas |
| `color.danger` | `#F04C4C` | Erro, cancelamento, fim de partida |
| `color.black` | `#040415` | Preto Shifty (bordas, checado) |
| `color.disabled` | `#D9D9D9` | Fundo de elementos desabilitados |
| `color.gray.fill` | `#F4F5F7` | Preenchimentos neutros (checkbox não checado) |
| `color.background` | `#FAFAFA` | Fundo de telas |
| `color.surface` | `#FFFFFF` | Cards, inputs, superfícies elevadas |
| `color.text.primary` | `#1B1D21` | Texto principal |
| `color.text.secondary` | `#737373` | Legendas, metadados, placeholders |
| `color.text.muted` | `rgba(0,0,0,.5)` | Subtítulos de tela e rodapé (issue #269) |
| `color.gray.g100` | `#8F92A1` | Labels curtas em caixa alta (divisor "OU") |
| `color.surface.muted` | `#F3F6F8` | Superfície neutra — fundo de botões sociais |

### Semântica esportiva
- **Ao vivo / sucesso**: verde (`#4FBF67` / `#24D173`)
- **Fim de partida / negativo**: vermelho (`#F04C4C`)

## Tipografia

Família da marca: **DM Sans**, aplicada via pacote `google_fonts` (fetch em runtime com cache HTTP; offline cai na fonte padrão da plataforma, sem quebrar o app). Escala do Shifty:

| Token | Tamanho | Peso | Uso |
|---|---|---|---|
| `type.display` | 36 / 46 | bold | Headline 1 — destaques |
| `type.headline.md` | 24 / 34 | bold | Headline 2 — títulos de tela |
| `type.headline.sm` | 22 / 32 | bold | Headline 3 — títulos de seção |
| `type.title.lg` | 18 / 28 | bold | Headline 4 — cabeçalhos |
| `type.title.md` | 16 / 26 | bold | Headline 5 — subtítulos / cartões |
| `type.title.sm` | 14 / 24 | bold | Headline 6 — rótulos |
| `type.body` | 18 / 28 | regular | Paragraph 1 |
| `type.body.md` | 16 / 26 | regular | Paragraph 2 — corpo |
| `type.body.sm` | 14 / 24 | regular | Paragraph 3 — corpo secundário |

### Estilos nomeados (`AppTextStyles`)

Constantes em `frontend/packages/core/lib/src/theme/app_text_styles.dart`, com letter-spacing da spec do Figma. A família é herdada do tema; a cor pode ser ajustada no ponto de uso via `copyWith`.

| Token | Tamanho/Linha | Peso | Letter-spacing | Cor padrão | Uso |
|---|---|---|---|---|---|
| `headline1` | 36 / 46 | w700 | −1.6 | `text.primary` | H1 — títulos de destaque |
| `subtitle` | 24 / 34 | w400 | −0.8 | `text.muted` | Subtítulo de tela |
| `labelMedium` | 14 / 24 | w500 | −0.3 | parametrizável | Links e rótulos de checkbox |
| `paragraph` | 14 / 24 | w400 | −0.3 | `text.primary` | Parágrafo |
| `fieldLabel` | 12 / 16 | w400 | −0.2 | `text.primary` @40% | Rótulo flutuante de input |
| `overlineLabel` | 12 / 20 | w700 | +1 (uppercase) | `gray.g100` | Overline — divisor "OU" |
| `buttonText` | 14 / 24 | w700 | −0.3 | branco | Texto de botão primário |
| `footerLink` | 13 / 17 | w500 | −0.2 | `text.muted` | Link/texto de rodapé |

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

## Componentes (padrões do Shifty)

- **Inputs** (`InputDecorationTheme`): preenchidos (`surface`), `OutlineInputBorder` raio 16, conteúdo vertical ~64px, **rótulo sempre visível** (12/16 ls−0.2 @40% — `fieldLabel`); estados **Normal / Focado / Disabled / Error** (borda `text.primary` 1px Main/Dark / `primary` / `disabled` / `danger`)
- **Botões** (`FilledButton`/`ElevatedButton`/`OutlinedButton`): altura mínima **56px**, raio 16; variantes **Main** (fundo `primary`), **Disable** (fundo `disabled`, texto `textPrimary`), **Ghost** (borda `primary`)
- **Chip**: raio 10; selecionado com fundo `primary`; não selecionado com borda `black`
- **SelectableCard** (`widgets/selectable_card.dart`, validado na #290, revisado na #294): card de seleção única (comportamento de rádio por grupo) — `Material` `surface`, raio 16, elevação 1 (mesmo padrão do `Card` do app), padding interno 16, altura mín. 96px (72px compacto), grid gap 12; **sem borda permanente** — contornos só em estados específicos, como anel (`foregroundDecoration`) para não deslocar conteúdo: padrão card puro · hover tinta suave · foco contorno `primary` 2px · **selecionado** fundo `primary` SÓLIDO + label/descrição/ícone BRANCOS + badge invertido no canto superior direito (círculo branco 24px, ícone `primary`) · desabilitado 55% de opacidade. Tipografia: label `titleSmall` (14/24 w700), descrição 13/17 w500
- **SelectableChip** (#290/#292/#294): variação compacta (raio 10) para grupos com muitas opções (ex.: faixa etária), gap 8 em wrap; altura ~34px (padding 16×8), métricas estáveis entre estados, peso fixo w500, tipografia 13/17 (`footerLink`). **Padrão SEM bordas** — estado por preenchimento: não selecionado = fundo `gray.fill` + texto `textPrimary` · **selecionado** = fundo `primary` + texto **BRANCO**; anel de foco `primary` apenas na navegação por teclado (acessibilidade)
- **Regra de conteúdo sobre primário (#294)**: conteúdo sobre preenchimento `primary` (#FD6B22) usa **BRANCO** — decisão do produto; nota de acessibilidade: contraste branco/laranja ≈ 2,9:1, abaixo de WCAG AA (~4,5:1), aceito conscientemente para estados de seleção
- **Checkbox**: 24px, raio 2; checado `primary`, não checado `gray.fill`
- **Card**: `surface`, raio 16, elevação 1
- **AppBar**: fundo `primary`, texto branco, título centralizado
- **Estados**: `AppLoading` (carregando), `AppEmptyState` (vazio com ícone), `AppErrorState` (erro com "Tentar novamente")
- **Alvos de toque**: mín. 48px (ícones acionáveis); botões 56px

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
