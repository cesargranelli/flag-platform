# Kickster UI Kit — Referência (Figma)

Fonte: [Kickster - Live Score & News Sport Apps UI Kits (Community)](https://www.figma.com/design/bXGRAtra3DkMAPGKLLLaCQ/Kickster---Live-Score---News-Sport-Apps-UI-Kits--Community-?node-id=65-400&t=67roG8OiMcxZAG4W-0)

> Extraído via Figma REST API em 2026-08-29. JSONs brutos em `docs/design/figma-reference/`.
> Este documento é a fonte da verdade para a **nova identidade visual** do Flag Platform (substitui a paleta Shifty).

## Decisão de adoção

- **Marcas**: o kit Kickster é um UI kit de **Live Score & News Sport** — aderente ao domínio (flag football com placares ao vivo, notícias e campeonatos).
- **Migração**: aplicar **tela a tela**, começando pela home do `admin_web`. Nada hardcoded: tudo via tokens/ThemeExtension.
- **Estrutura**: a paleta Kickster mapeia para os tokens semânticos atuais (primary, secondary, success, danger, warning, surface, text, grayscale) — mudança centralizada, sem tocar nas telas.

## Paleta de cores (Style Guide — node 23:68)

| Token Kickster | HEX | Mapeamento semântico |
|---|---|---|
| **Primary** | `#083879` | `color.primary` — azul royal (marca) |
| **Secondary** | `#17153B` | `color.secondary` / `color.text.primary` — azul-escuro |
| **Success** | `#00C566` | `color.success` — verde |
| **Error** | `#E53935` | `color.danger` — vermelho |
| **Warning** | `#FACC15` | `color.warning` — amarelo |
| **Black** | `#111111` | `color.black` |
| **Line** | `#E3E7EC` | bordas claras |
| **Line Dark** | `#4A4A65` | bordas escuras |
| **Grayscale 100** | `#171725` | texto forte |
| **Grayscale 90** | `#434E58` | |
| **Grayscale 80** | `#66707A` | `color.text.secondary` |
| **Grayscale 70** | `#78828A` | |
| **Grayscale 60** | `#9CA4AB` | `color.disabled` |
| **Grayscale 50** | `#BFC6CC` | |
| **Grayscale 40** | `#D1D8DD` | |
| **Grayscale 30** | `#E3E9ED` | |
| **Grayscale 20** | `#ECF1F6` | `color.surface.muted` |
| **Grayscale 10** | `#FDFDFD` | `color.surface` |
| **BG** | `#FEFEFE` | `color.background` |
| **BG Secundário** | `#F6F8FE` | fundo azulado de cards/áreas |

### Cores observadas nos componentes (Home + Live Match — node 34417:1519 / 34428:1113)

Confirmadas em uso real: `#083879`, `#111111`, `#66707A`, `#9CA4AB`, `#D1D8DD`, `#E53935`, `#F6F8FE`, `#FEFEFE`, `#FFFFFF`, `#1C1C1E`, `#808080`, `#DADADA`, `#F2F2F2`.

## Tipografia (Style Guide — node 23:410)

- **Família**: **Plus Jakarta Sans** (todas as escalas) — substitui a DM Sans atual.
- Nota: a seção "Montserrat" do arquivo é o nome do grupo antigo; a fonte efetivamente aplicada em todos os estilos é **Plus Jakarta Sans**.

| Escala | Tamanho | Peso | Line-height | Letter-spacing |
|---|---|---|---|---|
| H1 | 48px | w700 | 56px | 0.24 |
| H2 | 40px | w700 | 48px | 0.20 |
| H3 | 32px | w700 | 40px | 0.16 |
| H4 | 24px | w700 | 32px | 0.12 |
| H5 | 20px | w600 | 28px | 0.10 |
| H6 | 18px | w600 | 26px | 0.09 |
| Body X-Large | 18px | w400–700 | 26px | 0.09 |
| Body Large | 16px | w400–700 | 24px | 0.08 |
| Body Medium | 14px | w400–700 | 22px | 0.07 |
| Body Small | 12px | w400–700 | 20px | 0.06 |
| Body X-Small | 10px | w400–700 | 18px | 0.05 |

### Variações de peso
- **Bold**: w700 · **SemiBold**: w600 · **Medium/Regular**: w500 (a "Regular" usa w500 no kit)
- Letter-spacing = `tamanho * 0.005` (ex.: 14px → 0.07; 16px → 0.08)

## Componentes mapeados (UI Design)

| Componente | Node | Uso no Flag Platform |
|---|---|---|
| Home | 34417:1519 | Home do admin_web / public_app |
| Live Match | 34428:1113 | Tela de jogo ao vivo (placar, timeline) |
| Standings | 34433:3457 | Classificação |
| Matches | 34430:2773 | Lista de jogos |
| Club Profile | 34435:3370 | Perfil de time/clube |
| Schedule | 34430:8892 | Agenda/rodadas |
| Streaming | 34436:5238 | (futuro) |
| News | 34439:7760 | (futuro) notícias |
| Match Detail (Stats/Summary/Lineups/H2H/Tables) | 34439:3457… | Detalhe de jogo |
| Sign In / Create Account / OTP / Forgot / Reset | 29522:1824… | Login/cadastro/recuperação |
| Profile / User Info / Change Password | 30020:2900… | Perfil de usuário |
| Payment / Subscription | 34443:3177… | (futuro) |
| Top Goal Scorer | 34442:3298 | Artilharia |

## Estrutura do Home (referência de layout)

- Header: logo + busca + navegação
- Slider de destaque (carrossel)
- Títulos de seção + "Card List" (lista de cards de jogo/notícia)
- Bottom navigation: Home / Live / News / Profile (mobile)

## Estrutura do Live Match (referência de placar)

- Top bar: voltar + título "Live Match" + ação
- Placar central (times × placar)
- Standing (classificação em lista)
- Cards de eventos/estatísticas

## Arquivos brutos salvos

- `docs/design/figma-reference/kickster_styleguide.json` — Colors + Typography
- `docs/design/figma-reference/kickster_components_home_live.json` — Home + Live Match