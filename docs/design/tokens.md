# Flag Platform — Design Tokens

Fonte da verdade visual para os apps (Flutter). Reflete `frontend/packages/core/lib/src/theme/app_colors.dart` e `app_theme.dart`. O agente de UX deve basear propostas nestes tokens — qualquer mudança de token deve ser proposta aqui e refletida no `core`.

## Cores

| Token | Valor | Uso |
|---|---|---|
| `color.primary` | `#1B3A6B` | Marca, AppBar, botões principais, destaque |
| `color.secondary` | `#2E5EA8` | Elementos secundários, links |
| `color.accent` | `#E8A33D` | Destaques/CTA pontuais |
| `color.success` | `#2E7D32` | Sucesso, status positivos, pontos |
| `color.danger` | `#C62828` | Erro, cancelamento, perigo |
| `color.background` | `#F5F6FA` | Fundo de telas |
| `color.surface` | `#FFFFFF` | Cards, inputs, superfícies elevadas |
| `color.text.primary` | `#1C1C1E` | Texto principal |
| `color.text.secondary` | `#6E6E73` | Legendas, metadados, placeholders |

## Tipografia

Família: padrão do Material 3 (Roboto). Escala:

| Token | Tamanho | Peso | Uso |
|---|---|---|---|
| `type.display` | 28 | bold | Telas de destaque |
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
