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
- Criar categoria (ex: Flag 5x5 Masculino)
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
        └── Category
              ├── Venue (campo)
              ├── Team
              │     └── TeamRoster ────── Athlete
              └── Round
                    └── Game
                          ├── Standing (calculado)
                          └── CheckIn (validação de atleta por jogo)
`

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