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
| `color.danger` | `#F04C4C` | Erro, cancelamento, fim de partida |
| `color.background` | `#FAFAFA` | Fundo de telas |
| `color.surface` | `#FFFFFF` | Cards, inputs, superfícies elevadas |
| `color.text.primary` | `#1B1D21` | Texto principal |
| `color.text.secondary` | `#737373` | Legendas, metadados, placeholders |

### Semântica esportiva
- **Ao vivo / sucesso**: verde (`#4FBF67` / `#24D173`)
- **Fim de partida / negativo**: vermelho (`#F04C4C`)

## Tipografia

Família da marca: **DM Sans** (bundle via Google Fonts será adicionado em tarefa futura; até lá, fallback da fonte padrão). Escala:

| Token | Tamanho | Peso | Uso |
|---|---|---|---|
| `type.display` | 36 | bold | Telas de destaque |
| `type.title.lg` | 24 | bold | Títulos de tela |
| `type.title.md` | 20 | bold | Títulos de seção |
| `type.title.sm` | 16 | w600 | Subtítulos / cartões |
| `type.body` | 16 | regular | Corpo |
| `type.body.sm` | 14 | regular | Corpo secundário |
| `type.label` | 12 | w600 | Rótulos de campo, chips |

## Espaçamento

Escala: `4, 8, 12, 16, 24, 32`. Uso típico: padding de tela `16`, espaçamento entre cards `12`, entre grupos `24`.

## Formas e elevação

| Token | Valor |
|---|---|
| `radius.input` | 8 |
| `radius.card` | 12 |
| `elevation.card` | 1 |

## Componentes (estados padrão)

- **Inputs**: preenchidos (`surface`), borda `OutlineInputBorder` (8), **rótulo sempre visível** (`FloatingLabelBehavior.always`)
- **Botões**: `FilledButton` com altura mínima **48px**, raio 8, fundo `primary`
- **AppBar**: fundo `primary`, texto branco, título centralizado
- **Estados**: `AppLoading` (carregando), `AppEmptyState` (vazio com ícone), `AppErrorState` (erro com "Tentar novamente")
- **Alvos de toque**: mín. 48px (botões e ícones acionáveis)

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
