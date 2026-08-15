# Flag Platform — Design Tokens

Fonte da verdade visual para os apps (Flutter). Reflete `frontend/packages/core/lib/src/theme/app_colors.dart` e `app_theme.dart`. O agente de UX deve basear propostas nestes tokens — qualquer mudança de token deve ser proposta aqui e refletida no `core`.

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

### Semântica esportiva
- **Ao vivo / sucesso**: verde (`#4FBF67` / `#24D173`)
- **Fim de partida / negativo**: vermelho (`#F04C4C`)

## Tipografia

Família da marca: **DM Sans** (bundle via Google Fonts será adicionado em tarefa futura; até lá, fallback da fonte padrão). Escala do Shifty:

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

- **Inputs** (`InputDecorationTheme`): preenchidos (`surface`), `OutlineInputBorder` raio 16, conteúdo vertical ~64px, **rótulo sempre visível**; estados **Normal / Disabled / Success / Error** (borda `textSecondary` 50% / `disabled` / `success` / `danger`)
- **Botões** (`FilledButton`/`ElevatedButton`/`OutlinedButton`): altura mínima **56px**, raio 16; variantes **Main** (fundo `primary`), **Disable** (fundo `disabled`, texto `textPrimary`), **Ghost** (borda `primary`)
- **Chip**: raio 10; selecionado com fundo `primary`; não selecionado com borda `black`
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

## Acessibilidade (mínimo)

- Contraste de texto ≥ 4.5:1 (texto secundário sobre `surface` validado)
- Foco visível em todos os interativos
- Rótulos sempre visíveis em formulários
- Estados de erro no campo e mensagem clara
