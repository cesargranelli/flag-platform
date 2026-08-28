# UX Review — Navigation Bar do Public App

**Data:** 2026-08-28  
**Componente:** `_FlagBottomBar` / `_NavItem` / `_ActiveBadge` em `frontend/apps/public_app/lib/src/widgets/public_shell.dart`  
**Referência Figma:** UI Kit Shifty (community)  
**Tokens do design system:** `docs/design/tokens.md`

---

## 1. Resumo da Pesquisa

### 1.1 Material Design 3 (Google)

O padrão MD3 para bottom navigation (`NavigationBar`) recomenda:

- **3 a 5 destinos** de igual importância.
- **Altura padrão:** 80dp.
- **Ícones + rótulos** sempre visíveis (não apenas ícones).
- **Indicador ativo:** pill/cápsula (`activeIndicator`) de 56×32dp com `colorSecondaryContainer`.
- **Ícones:** 24dp; preenchido (filled) quando ativo, contornado (outlined) quando inativo.
- **Contraste:** `colorOnSurfaceVariant` (inativo) vs `colorPrimary`/`colorSecondary` (ativo).
- **Responsivo:** `NavigationBar` → `NavigationRail` (medium) → `NavigationDrawer` (expanded).

Referência: [m3.material.io/components/navigation-bar](https://m3.material.io/components/navigation-bar)

### 1.2 iOS Human Interface Guidelines (Apple)

- **Tab bar flutuante** sobre o conteúdo (iOS 26 Liquid Glass).
- **Sempre visível** (exceto sobre modais).
- **Ícone + rótulo** para cada aba — rótulo é obrigatório para navegação.
- **3 a 5 abas** (evitar overflow/"More" tab).
- **Nunca desabilitar** abas — se vazio, explicar por quê.
- **Badges** para informações críticas (não Diluir impacto).
- **Minimização no scroll** (iOS 26): tab bar encolhe quando rola para baixo.

Referência: [Apple HIG — Tab Bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)

### 1.3 Aplicativos Esportivos (ESPN, SofaScore, FlashScore)

| App | Nº de abas | Rótulos? | Indicador ativo | Fundo | Estilo |
|-----|-----------|----------|-----------------|-------|--------|
| **ESPN** | 4 (Home, Scores, Watch, News/Profile) | Sim | Pill preenchido + cor da marca | Claro | Tab bar nativa |
| **SofaScore** | 5 (Matches, Leagues, Favorites, Feed, Profile) | Sim | Texto em bold + ícone filled | Claro | Tab bar nativa |
| **Flashscore** | 5+ (varia por região) | Sim | Texto em bold + indicador colorido | Claro | Tab bar nativa |

**Padrão claro:** Todos os apps esportivos de sucesso usam **rótulos visíveis** + **ícones filled/contornado** + **indicador pill/clássico**. Nenhum usa ícones isolados sem rótulo.

### 1.4 Flutter Web (Boas Práticas 2024-2026)

- **`NavigationBar` (M3)** é o widget recomendado para novos apps Flutter (substituiu `BottomNavigationBar`).
- **Floating pill bar** é o estilo indie/consumer mais popular (2024-2026) — barra arredondada flutuando sobre o conteúdo.
- **`StatefulShellRoute.indexedStack`** preserva estado entre abas (já implementado no Flag Platform).
- **Alvos de toque:** mínimo 48×48dp; barra M3 padrão tem 56dp de altura.
- **Acessibilidade:** `Semantics(selected, label)` obrigatório; testar com TalkBack/VoiceOver.

Referência: [getwidget.dev — Flutter NavigationBar 2026](https://www.getwidget.dev/blog/flutter-navigation-bar/)

---

## 2. Comparação: Implementação Atual vs Padrões da Indústria

| Critério | Implementação Atual | Padrão da Indústria | Status |
|----------|--------------------|--------------------|--------|
| **Rótulos (labels)** | Ocultos — apenas ícones para itens inativos; rótulo só no Semantics | MD3, iOS HIG e apps esportivos: **sempre visíveis** | ⚠️ Crítico |
| **Ícone ativo** | Ícone primário dentro de círculo branco 52px | MD3: ícone filled + pill indicador; iOS: ícone filled | 🟡 Diferente (aceitável como estilo) |
| **Ícone inativo** | Ícone branco 24px, sem destaque | MD3: `colorOnSurfaceVariant` (cinza escuro); iOS: cinza médio | ⚠️ Alto — branco sobre fundo `#1B1D21` tem contraste ok, mas perde hierarquia |
| **Indicador ativo** | Círculo branco 52px + halo cinza 64px + barrinha `#333333` abaixo | MD3: pill 56×32dp com `colorSecondaryContainer`; iOS: preenchimento sutil | 🟡 Custom (estilo "Shifty" do Figma) |
| **Fundo da barra** | `#1B1D21` (preto) com raio 20, flutuante com margem 16 | MD3: `colorSurfaceContainer` (geralmente claro); iOS: Liquid Glass translúcido | 🟢 Consistente com design system Shifty |
| **Altura do item** | 60px (com círculo flutuante 64px total) | MD3: 80dp total; iOS: ~49pt | 🟡 Aceitável |
| **Alvo de toque** | `InkWell` com `borderRadius: 16` — área depende do Column | Mín. 48×48dp | 🟡 Precisa verificar — 60px de altura é suficiente, mas largura pode ser apertada com 3 itens |
| **Transição** | `goBranch()` (instantâneo) | MD3: animação pill; iOS: fade sutil | 🟡 Funcional, mas sem microinteração visual |
| **Responsividade** | `>=960px` → `NavigationRail` | MD3: `<600dp` bar / `600-839dp` rail / `840dp+` drawer | 🟢 Correto (breakpoint 960px) |
| **Semântica/Acessibilidade** | `Semantics(selected, button, label)` | `role="navigation"`, `aria-current`, `aria-label` | 🟢 Básico implementado |
| **Badge/Notificação** | Não implementado | MD3/iOS: badge vermelho com contagem | 🟡 Não applicable ainda |

---

## 3. Achados por Severidade

### 🔴 Crítico

**F1 — Ausência de rótulos visíveis nos itens de navegação**

- **Local:** `_NavItem` (linha 228-233)
- **Descrição:** Itens inativos mostram apenas ícone branco 24px. O rótulo ("Ao vivo", "Campeonato", "Sobre") está presente apenas no widget `Semantics`, invisível para usuários sighted.
- **Impacto:** Viola WCAG 1.1.1 (Non-text Content) e 1.3.1 (Info and Relationships). Usuários não conseguem identificar a aba sem depender da memória visual do ícone. Apps esportivos (ESPN, SofaScore, Flashscore) **sempre** mostram rótulos. Apple HIG: "Include tab labels to help with navigation." Material 3: "Always show labels."
- **Recomendação:** Adicionar rótulo `Text` abaixo de cada ícone (ativo e inativo). Usar `type.title.sm` (14/24 w700) para ativo e `type.body.sm` (14/24 regular) para inativo, conforme tokens existentes. No desktop (`NavigationRail`), os rótulos já estão presentes — manter consistência.

### 🟠 Alto

**F2 — Contraste do ícone inativo pode ser insuficiente**

- **Local:** `_NavItem` linha 232 — `Icon(icon, size: 24, color: Colors.white)` sobre fundo `#1B1D21`
- **Descrição:** Branco (`#FFFFFF`) sobre `#1B1D21` = contraste ≈ 16.6:1 (aceitável). Porém, a hierarquia visual entre ativo e inativo é fraca — ambos usam branco, diferenciados apenas pelo círculo.
- **Impacto:** Dificulta identificação rápida da aba ativa, especialmente em glare de luz solar.
- **Recomendação:** Usar `AppColors.textSecondary` (`#737373`) ou `AppColors.grayLabel` (`#8F92A1`) para ícones inativos, como fazem MD3 e apps esportivos. Isso cria hierarquia natural.

### 🟡 Médio

**F3 — Indicador ativo complexo (círculo + halo + barrinha)**

- **Local:** `_ActiveBadge` e `_NavItem` (linhas 256-305 e 235-247)
- **Descrição:** O item ativo usa 3 camadas: halo cinza 64px + círculo branco 52px + barrinha `#333333`. Total de 4 elementos visuais para indicar "esta aba está selecionada".
- **Impacto:** Sobrecarga visual. MD3 usa um único pill; iOS usa preenchimento sutil. O halo cinza `#C4C4C4` sobre fundo `#1B1D21` cria contraste desnecessário.
- **Recomendação (estilo Shifty mantido):** Simplificar para: círculo branco 52px com ícone primário + barrinha de destaque `AppColors.primary` (laranja). Remover o halo cinza — ele compet visualmente com o fundo escuro. Alternativamente, migrar para pill MD3 com `colorPrimary` como background do indicador.

### 🟡 Médio

**F4 — Sem microinteração de transição entre abas**

- **Local:** `_goToTab()` (linha 56-76)
- **Descrição:** `goBranch()` troca instantaneamente — sem animação de pill deslizando, sem fade, sem haptic feedback.
- **Impacto:** Perde oportunidade de dar feedback tátil/visual que confirma a ação. MD3 recomenda animação do pill indicador.
- **Recomendação:** Adicionar `AnimatedPositioned` para animar o indicador (pill ou círculo) entre posições. Duração: 200-300ms com `Curves.easeInOut`. Não é urgente, mas melhora a percepção de qualidade.

### 🟢 Baixo / Sugestão

**F5 — Raio 20 e margem 16 da barra flutuante**

- **Local:** `_FlagBottomBar` (linhas 159-161)
- **Descrição:** Raio 20 e margem 16 seguem o design system Shifty. Barra flutuante é o estilo indie mais popular em 2024-2026.
- **Impacto:** Positivo — alinha com tendências de UI consumer. Manter.

**F6 — Cor de fundo `#1B1D21`**

- **Local:** `_FlagBottomBar` (linha 163)
- **Descrição:** Fundo escuro é incomum para apps esportivos (ESPN, SofaScore usam fundo claro). Porém, é consistente com o UI Kit Shifty e cria contraste forte com o conteúdo claro.
- **Impacto:** Aceitável como escolha de marca. Se no futuro o produto quiser alinhar com concorrentes esportivos, considerar fundo claro com borda sutil.

---

## 4. Recomendações Específicas

### Recomendação 1: Adicionar rótulos visíveis (Crítico)

**O quê:** Mostrar o texto da aba abaixo do ícone para todos os itens (ativo e inativo).

**Por quê:** 
- MD3: "Always show labels (don't use icon-only)"
- iOS HIG: "Include tab labels to help with navigation"
- Todos os apps esportivos de sucesso mostram rótulos
- WCAG: melhora navegação por screen reader e reconhecimento visual

**Como:**
```dart
// Em _NavItem, substituir o Column por:
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    SizedBox(height: 60, child: /* ícone */),
    Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        color: selected ? AppColors.primary : AppColors.grayLabel,
      ),
    ),
  ],
)
```

**Tokens:** Usar `type.body.sm` (14/24) ou criar token `type.navLabel` (11/14 w500) para rótulos de nav bar.

### Recomendação 2: Melhorar hierarquia de cores (Alto)

**O quê:** Diferenciar cores de ícone ativo vs inativo.

**Por quê:** Cria hierarquia visual natural; alinha com MD3 e apps esportivos.

**Como:**
- Ícone ativo: `AppColors.primary` (#FD6B22) — já implementado
- Ícone inativo: `AppColors.grayLabel` (#8F92A1) — substituir `Colors.white`
- Rótulo ativo: `AppColors.primary`
- Rótulo inativo: `AppColors.grayLabel`

### Recomendação 3: Simplificar indicador ativo (Médio)

**O quê:** Reduzir de 4 camadas para 2: círculo branco + barrinha de destaque.

**Por quê:** Halo cinza `#C4C4C4` é visualmente pesado e compet com o fundo escuro. Barrinha `#333333` tem contraste baixo com `#1B1D21`.

**Como:**
- Remover `_ActiveBadge` halo (SizedBox 64px cinza)
- Manter círculo branco 52px com ícone primário
- Trocar barrinha `#333333` por `AppColors.primary` (laranja) — cria link visual com a cor da marca
- Alternativa: pill MD3 estilo `colorPrimary` com opacidade 0.12

### Recomendação 4: Adicionar animação de transição (Médio)

**O quê:** Animar o indicador ao trocar de aba.

**Por quê:** Confirma visualmente a ação do usuário; melhora percepção de qualidade.

**Cómo:**
- Usar `AnimatedPositioned` dentro de um `Stack` para animar o círculo/pill entre posições
- Duração: 200-300ms, curva `Curves.easeInOut`
- Respeitar `MediaQuery.disableAnimations` para acessibilidade

### Recomendação 5: Verificar alvos de toque (Baixo)

**O quê:** Garantir que cada aba tenha alvo de toque mínimo de 48×48dp.

**Por quê:** WCAG 2.5.8; os 3 itens em `Row` com `Expanded` dividem a largura igualmente — em telas estreitas (~320px), cada item tem ~100px de largura (suficiente). Mas testar em dispositivos reais.

**Como:**
- Adicionar `minHeight: 48` ao InkWell ou usar `ConstrainedBox`
- Verificar com ferramentas de inspeção Flutter

---

## 5. Referências Visuais

| Referência | URL | Relevância |
|-----------|-----|------------|
| Material 3 Navigation Bar | https://m3.material.io/components/navigation-bar | Padrão oficial MD3 |
| Apple HIG Tab Bars | https://developer.apple.com/design/human-interface-guidelines/tab-bars | Padrão iOS |
| Sofascore redesign 2025 | https://www.sofascore.com/news/sofascores-new-home-screen | Bottom bar com rótulos |
| ESPN app UI | https://screensdesign.com/showcase/espn-live-sports-scores | Tab bar nativa esportiva |
| Flutter NavigationBar 2026 | https://www.getwidget.dev/blog/flutter-navigation-bar/ | Comparação M2 vs M3 |
| Flutter Kit — 12 nav bars | https://theflutterk.it.com/blog/beautiful-bottom-navigation-bar-flutter | Variantes floating pill |
| iOS 26 Liquid Glass tabs | https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/ | Tab bar moderna iOS |
| BBC GEL Bottom Navigation | https://bbcbreakingnews.pages.dev/gel/features/bottom-navigation | Acessibilidade |

---

## 6. Conclusão

A barra de navegação do Public App tem uma **base sólida**: usa `StatefulShellRoute` para preservar estado, tem breakpoint responsivo correto, e o estilo flutuante "Shifty" é consistente com o design system. As principais lacunas são:

1. **Rótulos ausentes** — é o problema de usabilidade/acessibilidade mais impactante e mais fácil de resolver.
2. **Hierarquia de cores fraca** — ícones ativo/inativo não se diferenciam suficientemente.
3. **Indicador complexo** — 4 camadas visuais podem ser simplificadas.

Nenhuma mudança compromete a identidade visual do UI Kit Shifty — as recomendações podem ser implementadas preservando o estilo flutuante escuro com círculo branco.
