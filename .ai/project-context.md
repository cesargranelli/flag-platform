# Flag Platform — Project Context

## Objetivo

Construir uma plataforma configurável para organizações de Flag Football
gerenciarem campeonatos e oferecerem uma experiência moderna para atletas,
organizadores e torcedores.

O projeto nasce de uma **dor real**: aplicativo atual com baixa qualidade,
site inoperante, dificuldade de consulta de informações e acompanhamento
de jogos. O criador é um atleta que joga Flag Football em São Paulo.

## Visão

> "O melhor lugar para acompanhar um campeonato de flag."

Não criar um ERP esportivo. Criar algo simples, útil e utilizável.

## Primeiro Cliente

**APFA — Associação Paulista de Futebol Americano**

## Primeiro Campeonato Alvo

- Flag Football 5x5 Masculino
- Aproximadamente 30 equipes
- Fase de grupos + playoffs

## Papel deste Agente

Você é o **desenvolvedor executor**.

Antes de implementar qualquer coisa:

1. Leia este arquivo
2. Leia todos os ADRs em `docs/adr/`
3. Respeite as decisões existentes
4. Não crie abstrações sem necessidade
5. Pergunte quando houver dúvida de domínio

## MVP — Funcionalidades

### Para o Organizador (Admin Web — Flutter Web)
- Login (JWT)
- Criar organização
- Criar campeonato
- Criar categoria (combinação modalidade + gênero + faixa etária; ex: Flag 5x5 Masculino Adulto)
- Cadastrar campos/venues
- Cadastrar times
- Cadastrar atletas e inscrever no roster dos times
- Criar rodadas e jogos
- Publicar campeonato

### Para a Mesa / Delegado (Referee App — Flutter mobile, requer login)
- Iniciar partida
- Atualizar placar
- Validar atletas no pré-jogo e durante a partida
- Finalizar partida

### Para o Público / Atletas (Public App — Flutter mobile, sem login)
- Consultar calendário de jogos
- Acompanhar resultados
- Visualizar classificação
- Ver detalhes do jogo

## Fora do MVP

- Estatísticas por jogada / scout
- Streaming / transmissão
- Ranking avançado histórico
- QR code para validação de atleta (evolução futura — hoje check-in por lista de roster)

## Modelo de Domínio (MVP)

`
Organization
  └── Competition
        └── Category (modalidade + gênero + faixa etária)
              ├── Modality (catálogo: Flag 5x5, 8x8, 9x9, Full Pads 11x11)
              ├── Venue (campo)
              ├── Team
              │     └── TeamRoster ────── Athlete
              └── Round
                    └── Game
                          ├── Standing (calculado)
                          └── CheckIn (validação de atleta por jogo)
`

> **Categoria estruturada**: desde as issues #177/#178, a categoria não é mais um nome livre. É a combinação **modalidade + gênero + faixa etária** — ex.: "Flag 5x5 Masculino Adulto". O nome é derivado automaticamente (override opcional). Enums: `Gender` (MALE/FEMALE/MIXED) e `AgeGroup` (SUB11/SUB13/SUB14/SUB15/SUB17/SUB20/ADULT/MASTER/OPEN).

## Stack

### Backend
- Java 21
- Spring Boot 3.x
- Spring Data JPA + Spring Validation + Spring Security
- PostgreSQL (schema: `platform`)
- Flyway (migrações)
- SpringDoc OpenAPI (Swagger)

### Frontend
- Flutter (3 aplicativos: Public App mobile, Referee App mobile, Admin Web)
- Dio + Riverpod + GoRouter (base já configurada em frontend/)

### API
- REST — versionamento: `/api/v1`
- JWT Bearer para clientes autenticados

## Organização de Cada Módulo Backend

`
modules/{nome}/
├── controller/
├── service/
├── repository/
├── entity/
├── dto/
├── mapper/
└── validation/
`

## Regras de Desenvolvimento

### FAZER
- Funcionalidades que resolvam a dor do atleta ou do organizador
- Commits pequenos e descritivos
- Testes nos serviços principais
- Documentar API com OpenAPI
- Usar Flyway para todas alterações de schema

### NÃO FAZER
- Microsserviços / Kubernetes / Kafka
- CQRS / Event Sourcing
- Abstrações antecipadas

## Regras de Fluxo — Issues e Branches (GitHub)

Regras obrigatórias para toda issue criada no repositório `cesargranelli/flag-platform`:

1. **Assinatura da issue**: toda issue deve ser atribuída (assignee) ao usuário **`cesargranellidev`**.
2. **Separação por subagente**: quando o escopo envolver mais de uma frente (backend, frontend/app, devops), criar **uma issue separada por subagente executor** — nunca uma issue única misturando escopos. Cada issue recebe os labels do seu escopo (`backend`, `frontend`, `app`, `admin-web`, etc.).
3. **Associação issue ↔ branch-feature**: o corpo de cada issue deve referenciar explicitamente a branch-feature em execução para aquela issue (ex.: `**Branch:** \`issue-{n}-{slug}\``). Uma branch por issue; a issue só é fechada após o merge da sua branch.

## Pergunta Principal

> "Isso ajuda uma organização de Flag Football a realizar um campeonato melhor?"

Se a resposta for não, fica fora do MVP.

## Autenticação

- **Público (Public App)**: sem login
- **Mesa / Delegado (Referee App)**: login obrigatório (role MESA)
- **Organizador (Admin Web)**: login obrigatório (role ORGANIZER/ADMIN)
- **Atleta**: opcional (fase futura)

---

## Handoff — 2026-08-14 (sessão de melhorias concluída)

> Este bloco foi adicionado para retomar o trabalho sem perder contexto. Resumo do estado atual do projeto.

### Estado do produto
- **Backend** (Spring Boot, modulith, `backend/`): 282 testes passando. Domínio completo (Organization → Competition → Category → Venue/Team/Round → Game → Standing; plus Athlete/Roster/CheckIn/ScoreEvents/User). Migrações Flyway até `V14`. Auth JWT com roles ADMIN/ORGANIZER/MESA; rate limit no login; paginação (page/size + `X-Total-Count`) em organizations, athletes, venues, competitions; `/actuator/prometheus` + health probes.
- **Frontend** (Flutter workspace em `frontend/`): 3 apps (public_app, referee_app, admin_web) + packages (api, core, domain). CI agora roda backend **e** frontend (melos analyze + test). Todos os épicos do backlog concluídos e issues fechadas.
- **Repositório**: `main` sincronizada. Nenhuma issue/epico aberto.

### Trabalho mais recente
- Criadas e implementadas as 9 issues de melhoria (#91–#99): gestão de usuários (ADMIN/MESA), frontend no CI, rótulos visíveis + nomes de times, layout responsivo (NavigationRail), paginação, rate limit, wizard de organização, i18n (AppStrings + flutter_localizations), observabilidade.
- Criação de **agente `ux-designer`** em `~/.config/opencode/agent/ux-designer.md` (config global do opencode). **Requer reiniciar o opencode para ficar disponível.**

### Próximos passos sugeridos (decisões pendentes do usuário)
- Iterar no agente `ux-designer` (tools de design/MCP, tokens do design system do Flag, skill de revisão de usabilidade, mode all).
- Evolução da fundação de i18n para todas as telas.
- Melhorias contínuas de UX (layout desktop nas telas de listagem, etc.).

### Como retomar a sessão
- `opencode --continue` (ou selecionar a sessão no TUI) para voltar exatamente a esta conversa.
- Se a sessão for perdida: este arquivo + `docs/product/backlog.md` + ADRs são o ponto de partida.

---

## Handoff — 2026-08-18 (épico #176: reestruturação de competições)

### Estado atual
- **Épico #176** "Reestruturar modelo de competições: modalidade, gênero e faixa etária" — **concluído**: #177 (backend), #178 (frontend) e #179 (testes E2E + documentação) todas **Done**. PRs #180, #181, #182 merged.
- **Backend**: 315 testes verdes. Novo módulo `modality` (catálogo) + categorias estruturadas (migrações Flyway até **V19**).
- **Frontend**: admin_web 65, api 11, domain 26, core 4, public 30, referee 15 — todos verdes.

### Decisão de escopo (registrada na #179)
- **Manter o padrão atual de testes** (widget tests com Fakes + unit tests puros + testes de integração backend). A migração para **Playwright/Selenium** (E2E consolidado, mantendo só unitários de negócio nas apps) foi **estudada e adiada** — ideia futura, fora do escopo atual.

### Modelo de competições (novo)
- **Categoria** = combinação **modalidade + gênero + faixa etária** (não mais nome livre).
- **Modalidade** = catálogo `modalities` (Flag 5x5/8x8/9x9, Full Pads 11x11), seed em runtime (`ModalityDataSeeder`), `GET /api/v1/modalities`.
- **Enums**: `Gender` (MALE/FEMALE/MIXED), `AgeGroup` (SUB11..OPEN).
- **Nome** derivado (ex.: "Flag Football 5x5 · Masculino · Adulto"), override opcional; unicidade por combinação.