# Flag Platform — Backlog

## Arquitetura Multi-Cliente

Uma unica API REST (`/api/v1`) atende a **tres clientes**:

| Cliente | Plataforma | Usuario | Login | Epico |
|---------|-----------|---------|-------|-------|
| **Public App** | Flutter mobile | Atletas / Torcedores | Sem login | #6 |
| **Referee App** | Flutter mobile | Mesa / Delegado | Obrigatorio | #7 |
| **Admin Web** | Flutter Web | Organizador | Obrigatorio | #35 |

Novo dominio (em relacao ao backlog anterior):

```
Organization
  └── Competition
        └── Category
              ├── Venue
              ├── Team
              │     └── TeamRoster ────── Athlete
              └── Round
                    └── Game
                          ├── Standing (calculado)
                          └── CheckIn (validacao de atleta por jogo)
```

## Ordem de Execucao

```
Fase 1 — Bootstrap
    #8 #11 #10 (paralelo)
         |
    #9 #12 (dependem de #8)
         |
Fase 2 — Dominio Core Backend
    #13 → #14 → #15 → #17 → #19
                  ↓              ↓
                 #16 ──────────→ #19
                  ↓
                 #18 ──────────→ #19
                                    |
Fase 3 — Operacao e Classificacao (backend)
                                #21 → #20 → #22 → #23
                                                      |
Fase 4 — Autenticacao e Cadastros (base para apps com login)
        #36 → #37 → #38 → #39 → #40
                          (paralelo)        Admin Web: #43 → #44-#51
                                                      |
Fase 5 — Experiencia Publica (Public App)
                                    #24 #25 #26 #27 #28
                                                      |
Fase 6 — Live Game + Validacao (Referee App)
                                    #52 → #41 → #42 → #29 → #30 → #53
```

---

## Fase 1 — Bootstrap (Epico #1)

> Prerequisito para todo o desenvolvimento. Nada pode ser iniciado sem esta fase concluida.

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 1 | #8 Configurar backend Spring Boot | Tarefa | — |
| 2 | #11 Configurar Docker Compose | Tarefa | — |
| 3 | #10 Configurar Flutter (frontend base) | Tarefa | — |
| 4 | #9 Configurar banco de dados e Flyway | Tarefa | #8 |
| 5 | #12 Configurar Swagger / OpenAPI | Tarefa | #8 |
| 6 | #54 Reestruturar frontend para multi-app (Public, Referee, Admin Web) | Tarefa | #10 |

**Obs:** #8, #11 e #10 podem ser executadas em paralelo. #9 e #12 dependem de #8. #54 cria a estrutura `frontend/apps/*` + `frontend/packages/*` (melos) e é pré-requisito das histórias dos 3 apps.

---

## Fase 2 — Dominio Core Backend (Epicos #3)

> Construir o dominio de baixo para cima, respeitando as foreign keys do banco.
> Ordem obrigatoria: Organization → Competition → Category → (Venue, Team, Round) → Game

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 7 | #13 Criar e gerenciar organizacao | Historia | Fase 1 |
| 8 | #14 Criar e gerenciar campeonato | Historia | #13 |
| 9 | #15 Criar e gerenciar categoria | Historia | #14 |
| 10 | #16 Cadastrar campos de jogo (venues) | Historia | #13 |
| 11 | #17 Cadastrar times do campeonato | Historia | #15 |
| 12 | #18 Criar rodadas do campeonato | Historia | #15 |
| 13 | #19 Criar e agendar jogos | Historia | #17 + #18 + #16 |

**Obs:** #16 (Venue) pode ser feito em paralelo com #15 (Category), ambos dependem apenas de #14 (Competition) e #13 (Organization) respectivamente. Consumido pelo **Admin Web** (#35).

---

## Fase 3 — Operacao e Classificacao (Epicos #4 e #5)

> Depende da Fase 2 completa. O status do jogo deve existir antes do registro de resultado.

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 14 | #21 Gerenciar status do jogo | Historia | #19 |
| 15 | #20 Registrar resultado de partida | Historia | #21 |
| 16 | #22 Calcular classificacao automaticamente | Historia | #20 |
| 17 | #23 Consultar classificacao publica | Historia | #22 |

**Obs:** #21 e #20 sao consumidos pelo **Referee App** (#7). #23 e consumido pelo **Public App** (#6).

---

## Fase 4 — Autenticacao e Cadastros (Epicos #32 e #33)

> Pre-requisito para os apps com login (Admin Web e Referee App).

### Autenticacao e Autorizacao (Epico #32)

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 18 | #36 Cadastro de usuario e login com JWT | Historia | Fase 1 |
| 19 | #37 Autorizacao por roles (ADMIN, ORGANIZER, MESA) | Historia | #36 |

### Atletas e Roster (Epico #33)

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 20 | #38 CRUD de atleta | Historia | #13 |
| 21 | #39 Gerenciar roster (inscricao de atleta em time) | Historia | #17 + #38 |
| 22 | #40 Consulta publica de elenco de time | Historia | #39 |

**Obs:** #38 e #39 sao consumidos pelo **Admin Web** (#35). #40 sera consumido pelo **Public App** em fase futura.

### Admin Web — Gestao de Cadastros (Epico #35)

> Toda a gestao de cadastros migra do Swagger para esta aplicacao web (Flutter Web).

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 23 | #43 Login do organizador (Admin Web) | Historia | #36 |
| 24 | #44 Gestao de organizacoes | Historia | #43 + #13 |
| 25 | #45 Gestao de campeonatos | Historia | #43 + #14 |
| 26 | #46 Gestao de categorias | Historia | #45 + #15 |
| 27 | #47 Gestao de campos | Historia | #43 + #16 |
| 28 | #48 Gestao de times | Historia | #46 + #17 |
| 29 | #49 Gestao de rodadas | Historia | #46 + #18 |
| 30 | #50 Gestao de jogos | Historia | #49 + #19 |
| 31 | #51 Gestao de atletas e rosters | Historia | #38 + #39 |

---

## Fase 5 — Experiencia Publica (Epico #6)

> Pode iniciar apos Fase 2 concluida. Algumas telas dependem tambem da Fase 3.

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 32 | #24 Tela inicial — lista de campeonatos | Historia | #14 |
| 33 | #25 Calendario de jogos | Historia | #19 |
| 34 | #26 Resultados recentes | Historia | #20 |
| 35 | #27 Tabela de classificacao (Flutter) | Historia | #23 |
| 36 | #28 Detalhes do jogo | Historia | #19 |

**Obs:** #24, #25 e #28 podem iniciar assim que a Fase 2 estiver pronta. #26 e #27 dependem da Fase 3.

---

## Fase 6 — Live Game + Validacao de Atletas (Epicos #7 e #34)

> Depende da Fase 3 completa, da tela de detalhes (#28) no Public App e do login da mesa (#52).

### Validacao de Atletas (Epico #34)

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 37 | #41 Check-in de atletas no pre-jogo | Historia | #21 + #39 |
| 38 | #42 Validacao de atleta durante a partida | Historia | #41 |

### Aplicativo da Mesa — Referee App (Epico #7)

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 39 | #52 Login da mesa (Referee App) | Historia | #36 |
| 40 | #29 Iniciar e finalizar partida ao vivo | Historia | #21 + #28 + #52 |
| 41 | #30 Atualizar placar ao vivo | Historia | #29 |
| 42 | #53 Tela de check-in e validacao de atletas | Historia | #41 + #29 + #52 |

---

## Resumo por Release

| Release | Escopo | Epicos | Issues |
|---------|--------|--------|--------|
| **v0.1 — Foundation** | Backend core + operacao + classificacao | #1, #3, #4, #5 | #8 ao #23 |
| **v0.2 — Cadastros + Publico** | Reestruturacao frontend, auth, atletas/roster, Admin Web e Public App | #32, #33, #35, #6 | #54, #36 ao #51, #24 ao #28 |
| **v0.3 — Live Game** | Validacao de atletas e Referee App | #34, #7 | #41, #42, #52, #29, #30, #53 |

---

## Resumo por Epico

| # | Epico | Release | Clientes |
|---|-------|---------|----------|
| 1 | Bootstrap do Projeto | v0.1 | infra |
| 3 | Gestao de Campeonato | v0.1 | Admin Web |
| 4 | Operacao de Partidas | v0.1 | Referee App |
| 5 | Classificacao | v0.1 | Public App |
| 32 | Autenticacao e Autorizacao | v0.2 | Admin Web + Referee App |
| 33 | Atletas e Roster | v0.2 | Admin Web (+ Public App fut.) |
| 35 | Aplicacao Web de Administracao (Admin Web) | v0.2 | Admin Web |
| 6 | Aplicativo Publico (Public App) | v0.2 | Public App |
| 34 | Validacao de Atletas | v0.3 | Referee App |
| 7 | Aplicativo da Mesa (Referee App) | v0.3 | Referee App |

## Tarefas estruturais

| # | Tarefa | Release | Depende de |
|---|--------|---------|------------|
| 54 | Reestruturar frontend para multi-app (Public, Referee, Admin Web) | v0.2 | #10 |
