# Admin Web — Referências de design (login/signup + timeline de jogos)

Pesquisa web (2026-08-14). Fontes e padrões extraídos para embasar a proposta do novo fluxo de login/signup do Admin Web e de uma futura **timeline de eventos de jogos**.

## Login / Signup — templates de apps esportivos

### Fontes
- **Figma Community — "Sports Login UI Mobile"** → `figma.com/community/file/1529891614564171873/sports-login-ui-mobile`
  - Login + Sign Up (com verificação por e-mail/telefone e contas de responsável) + fluxo de recuperação de conta. Tema escuro, onboarding limpo.
- **Figma Community — templates de login** → `figma.com/community/mobile-apps/login-page` (100+ templates)
- **Muzli — 60+ Best Login screen examples (2026)** → `muz.li/inspiration/login-screen/`
- **Dribbble — "Login & Signup Page UI" (Fitness App)** → `dribbble.com/shots/26530819`
- **ThemeForest** (apps esportivos de livescore): "Monster - Livescore Sport app ui kit", "Scorex - Livescore Sport App Template (Tailwind + PWA)"
- **Jotform** (sports app templates) e **Uizard** (sports app UI template)

### Padrões relevantes para o Admin Web
- Login e Signup na **mesma tela** (toggle/abas), com "Esqueci a senha" ao lado
- Signup com **confirmação** (e-mail/telefone) → alinha com o nosso fluxo de **aprovação** (no nosso caso, aprovação por super usuário em vez de auto-verificação)
- Fluxo de **recuperação de conta** com passo a passo (e-mail → link → nova senha)
- Layout centralizado, tema limpo; muito comum tema escuro em apps esportivos (podemos manter o claro por enquanto, conforme tokens)

## Timeline de eventos de jogos

### Fontes
- **Broadage — Soccer Timeline Widget** → `broadage.com/sports-data-widgets/soccer/timeline`
  - Os 90 minutos em **uma linha vertical**; eventos (gols, pênaltis, substituições, cartões) posicionados no **minuto** correspondente.
- **Dribbble — "World Cup 2026 Live Match Timeline UI"** → `dribbble.com/shots/27163994`
  - Timeline cronológica dos momentos-chave (gols, assistências, cartões), layout estruturado para o jogo se desenrolar.
- **api-sport.pro — Interactive live timeline (goals, strikes, cards)** → `api-sport.pro/how-to-create-an-interactive-live-timeline-goals-strikes-cards/`
- **Figma — "UEFA Champions League Football App UI/UX"** → `figma.com/community/file/1353694526296501652`
  - Placar e comentários em tempo real; hierarquia de informação clara.

### Padrões relevantes para o Flag Platform (futuro — Public/Referee App)
- **Linha do tempo vertical** cobrindo a duração da partida
- **Eventos por minuto**: ponto (+1) no nosso caso; futuramente outros eventos
- **Alinhamento por time**: eventos do time da casa de um lado, visitante do outro (padrão futebol)
- **Ícones por tipo de evento** + horário/minuto + descrição
- Atualização em tempo real (já temos o placar ao vivo; a timeline pode consumir `score_events`)

## Como usar

- O agente `ux-designer` deve consultar este arquivo ao propor o novo login/signup e qualquer tela de jogo ao vivo.
- Linkar referências a decisões: ver `docs/design/ux/admin-web-login.md`.
