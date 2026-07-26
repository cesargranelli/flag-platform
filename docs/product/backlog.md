# Flag Platform — Backlog

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
Fase 3 — Operacao e Classificacao
                                #21 → #20 → #22 → #23
                                                     |
Fase 4 — Experiencia Publica (Flutter)
                        #24 #25 #26 #27 #28 (paralelo apos Fase 2+3)
                                                     |
Fase 5 — Live Game
                                              #29 → #30
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

**Obs:** #8, #11 e #10 podem ser executadas em paralelo. #9 e #12 dependem de #8.

### TASK-001 — #8 Configurar backend Spring Boot

Criterios de aceitacao:
- [ ] Projeto compila sem erros
- [ ] Estrutura de pacotes criada: common, config, security, modules/*
- [ ] SecurityConfig minima: endpoints publicos liberados, protegidos exigem autenticacao
- [ ] GlobalExceptionHandler com resposta padronizada de erros
- [ ] Maven Wrapper (mvnw) adicionado
- [ ] application-local.yml criado com perfil de desenvolvimento
- [ ] Health check respondendo em /actuator/health
- [ ] Testes de contexto Spring passando (src/test/)

### TASK-002 — #9 Configurar banco de dados e Flyway

Criterios de aceitacao:
- [ ] PostgreSQL rodando via Docker Compose
- [ ] Schema 'platform' criado via Flyway
- [ ] V1 migration executada com sucesso
- [ ] Todas as tabelas do dominio criadas com indices

### TASK-003 — #10 Configurar Flutter (frontend base)

Criterios de aceitacao:
- [ ] flutter pub get sem erros
- [ ] Estrutura de pastas: lib/core/, lib/features/, lib/shared/
- [ ] Riverpod configurado com ProviderScope
- [ ] GoRouter configurado com rotas iniciais
- [ ] Tela inicial exibindo nome do app

### TASK-004 — #11 Configurar Docker Compose

Criterios de aceitacao:
- [ ] docker-compose up sobe PostgreSQL
- [ ] Banco acessivel em localhost:5432
- [ ] pgAdmin disponivel com profile tools
- [ ] .env.example documentando variaveis necessarias
- [ ] README atualizado com instrucoes

### TASK-005 — #12 Configurar Swagger / OpenAPI

Criterios de aceitacao:
- [ ] OpenApiConfig com titulo, versao e descricao do projeto
- [ ] Swagger UI acessivel em /swagger-ui.html
- [ ] API docs em /api-docs
- [ ] Autenticacao JWT configurada no Swagger UI

---

## Fase 2 — Dominio Core Backend (Epicos #2 e #3)

> Construir o dominio de baixo para cima, respeitando as foreign keys do banco.
> Ordem obrigatoria: Organization → Competition → Category → (Venue, Team, Round) → Game

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 6 | #13 Criar e gerenciar organizacao | Historia | Fase 1 |
| 7 | #14 Criar e gerenciar campeonato | Historia | #13 |
| 8 | #15 Criar e gerenciar categoria | Historia | #14 |
| 9 | #16 Cadastrar campos de jogo (venues) | Historia | #13 |
| 10 | #17 Cadastrar times do campeonato | Historia | #15 |
| 11 | #18 Criar rodadas do campeonato | Historia | #15 |
| 12 | #19 Criar e agendar jogos | Historia | #17 + #18 + #16 |

**Obs:** #16 (Venue) pode ser feito em paralelo com #15 (Category), ambos dependem apenas de #14 (Competition) e #13 (Organization) respectivamente.

### ISSUE-001 — #13 Organization
**Como** organizador
**Quero** criar e gerenciar minha organizacao esportiva
**Para** que ela seja o ponto central de todos os meus campeonatos

Criterios de aceitacao:
- [ ] POST /api/v1/organizations
- [ ] GET /api/v1/organizations — listar (publico)
- [ ] GET /api/v1/organizations/{id} — detalhe (publico)
- [ ] PUT /api/v1/organizations/{id} — atualizar (autenticado)
- [ ] Validacao: nome obrigatorio, slug unico
- [ ] Testes unitarios no OrganizationService
- [ ] API documentada no Swagger

### ISSUE-002 — #14 Competition
**Como** organizador
**Quero** criar um campeonato dentro da minha organizacao
**Para** comecar a estruturar os jogos

Criterios de aceitacao:
- [ ] POST /api/v1/competitions
- [ ] GET /api/v1/competitions/{id} (publico)
- [ ] GET /api/v1/organizations/{id}/competitions (publico)
- [ ] PUT /api/v1/competitions/{id} (autenticado)
- [ ] Status: DRAFT, PUBLISHED, FINISHED
- [ ] Testes unitarios
- [ ] API documentada no Swagger

### ISSUE-003 — #15 Category
**Como** organizador
**Quero** criar categorias dentro de um campeonato (ex: Masculino 5x5, Feminino)
**Para** organizar os times por modalidade

Criterios de aceitacao:
- [ ] POST /api/v1/categories
- [ ] GET /api/v1/competitions/{id}/categories (publico)
- [ ] PUT /api/v1/categories/{id} (autenticado)
- [ ] DELETE /api/v1/categories/{id} (autenticado)
- [ ] Testes unitarios
- [ ] API documentada

### ISSUE-004 — #16 Venue
**Como** organizador
**Quero** cadastrar os campos onde os jogos acontecem
**Para** que atletas saibam onde jogar

Criterios de aceitacao:
- [ ] POST /api/v1/venues
- [ ] GET /api/v1/venues (publico)
- [ ] GET /api/v1/venues/{id} (publico)
- [ ] PUT /api/v1/venues/{id} (autenticado)
- [ ] Campos: nome, endereco, link do mapa (opcional)
- [ ] Testes unitarios
- [ ] API documentada

### ISSUE-005 — #17 Team
**Como** organizador
**Quero** cadastrar os times participantes de uma categoria
**Para** montar a tabela e criar os jogos

Criterios de aceitacao:
- [ ] POST /api/v1/teams
- [ ] GET /api/v1/categories/{id}/teams (publico)
- [ ] GET /api/v1/teams/{id} (publico)
- [ ] PUT /api/v1/teams/{id} (autenticado)
- [ ] Campos: nome, sigla, logo_url (opcional)
- [ ] Testes unitarios
- [ ] API documentada

### ISSUE-006 — #18 Round
**Como** organizador
**Quero** criar rodadas dentro de uma categoria
**Para** organizar os jogos em grupos ou fases

Criterios de aceitacao:
- [ ] POST /api/v1/rounds
- [ ] GET /api/v1/categories/{id}/rounds (publico)
- [ ] PUT /api/v1/rounds/{id} (autenticado)
- [ ] Campos: numero, nome, tipo (REGULAR, PLAYOFFS)
- [ ] Testes unitarios
- [ ] API documentada

### ISSUE-007 — #19 Game
**Como** organizador
**Quero** criar jogos dentro de uma rodada
**Para** publicar o calendario do campeonato

Criterios de aceitacao:
- [ ] POST /api/v1/games
- [ ] GET /api/v1/rounds/{id}/games (publico)
- [ ] GET /api/v1/games/{id} (publico)
- [ ] PUT /api/v1/games/{id} — atualizar horario ou campo (autenticado)
- [ ] Campos: homeTeam, awayTeam, venue, scheduledAt
- [ ] Status inicial: SCHEDULED
- [ ] Testes unitarios
- [ ] API documentada

---

## Fase 3 — Operacao e Classificacao (Epicos #4 e #5)

> Depende da Fase 2 completa. O status do jogo deve existir antes do registro de resultado.

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 13 | #21 Gerenciar status do jogo | Historia | #19 |
| 14 | #20 Registrar resultado de partida | Historia | #21 |
| 15 | #22 Calcular classificacao automaticamente | Historia | #20 |
| 16 | #23 Consultar classificacao publica | Historia | #22 |

### ISSUE-008 — #21 Game Status
**Como** mesa/delegado
**Quero** atualizar o status de um jogo
**Para** refletir o estado real da partida

Criterios de aceitacao:
- [ ] PATCH /api/v1/games/{id}/status
- [ ] Transicoes validas: SCHEDULED→IN_PROGRESS, IN_PROGRESS→FINISHED, SCHEDULED→CANCELLED
- [ ] Requer autenticacao (role MESA ou ADMIN)
- [ ] Testes unitarios
- [ ] API documentada

### ISSUE-009 — #20 Game Result
**Como** mesa/delegado
**Quero** registrar o placar final de um jogo
**Para** que o resultado fique disponivel e a classificacao seja atualizada

Criterios de aceitacao:
- [ ] POST /api/v1/games/{id}/result
- [ ] Campos: homeScore, awayScore
- [ ] Jogo passa para status FINISHED
- [ ] Standing recalculado automaticamente apos registro
- [ ] Nao permite sobrescrever resultado sem permissao de ADMIN
- [ ] Requer autenticacao (role MESA ou ADMIN)
- [ ] Testes unitarios
- [ ] API documentada

### ISSUE-010 — #22 Standing (calculo)
**Como** sistema
**Quero** recalcular a classificacao apos cada resultado
**Para** manter a tabela sempre atualizada

Criterios de aceitacao:
- [ ] StandingService.recalculate(categoryId) chamado apos resultado
- [ ] Calculo correto de: PJ, V, E, D, GP, GC, SG, PTS
- [ ] Criterios de desempate: pontos > saldo > gols pro
- [ ] Upsert na tabela standing
- [ ] Testes unitarios com cenarios de empate

### ISSUE-011 — #23 Standing (consulta publica)
**Como** atleta ou torcedor
**Quero** consultar a classificacao de uma categoria
**Para** saber a posicao do meu time no campeonato

Criterios de aceitacao:
- [ ] GET /api/v1/categories/{id}/standings (sem autenticacao)
- [ ] Ordenado por: pontos DESC, saldo DESC, gols pro DESC
- [ ] Campos: posicao, time, PJ, V, E, D, GP, GC, SG, PTS
- [ ] Testes unitarios
- [ ] API documentada

---

## Fase 4 — Experiencia Publica Flutter (Epico #6)

> Pode iniciar apos Fase 2 concluida. Algumas telas dependem tambem da Fase 3.

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 17 | #24 Tela inicial — lista de campeonatos | Historia | #14 |
| 18 | #25 Calendario de jogos | Historia | #19 |
| 19 | #26 Resultados recentes | Historia | #20 |
| 20 | #27 Tabela de classificacao (Flutter) | Historia | #23 |
| 21 | #28 Detalhes do jogo | Historia | #19 |

**Obs:** #24, #25 e #28 podem iniciar assim que a Fase 2 estiver pronta. #26 e #27 dependem da Fase 3.

### ISSUE-012 — #24 Tela inicial
**Como** atleta ou torcedor
**Quero** ver os campeonatos disponiveis ao abrir o app
**Para** escolher qual acompanhar

Criterios de aceitacao:
- [ ] Lista de campeonatos com nome, organizacao e status
- [ ] Navegar para detalhe ao tocar
- [ ] Loading state e estado vazio tratados
- [ ] Sem login necessario

### ISSUE-013 — #25 Calendario de jogos
**Como** atleta
**Quero** ver o calendario de jogos do campeonato
**Para** saber quando e onde vou jogar

Criterios de aceitacao:
- [ ] Lista de jogos ordenada por data
- [ ] Filtro por rodada
- [ ] Exibe: times, horario, campo
- [ ] Proximos jogos em destaque

### ISSUE-014 — #26 Resultados recentes
**Como** atleta ou torcedor
**Quero** ver os resultados dos jogos recentes
**Para** acompanhar o fim de semana

Criterios de aceitacao:
- [ ] Lista de jogos FINISHED com placar
- [ ] Ordenado por data decrescente
- [ ] Exibe: times, placar, campo, rodada

### ISSUE-015 — #27 Tabela de classificacao
**Como** atleta ou torcedor
**Quero** ver a classificacao no app
**Para** saber quem lidera o campeonato

Criterios de aceitacao:
- [ ] Tabela com posicao, time, PJ, V, D, SG, PTS
- [ ] Destaque para o lider
- [ ] Pull to refresh

### ISSUE-016 — #28 Detalhes do jogo
**Como** atleta ou torcedor
**Quero** ver os detalhes de um jogo especifico
**Para** ter todas as informacoes em um lugar

Criterios de aceitacao:
- [ ] Exibe: times, placar, campo, horario, status
- [ ] Link para mapa do campo
- [ ] Status visual: AGENDADO, AO VIVO, FINALIZADO

---

## Fase 5 — Live Game (Epico #7)

> Depende da Fase 3 completa e da tela de detalhes (#28) no Flutter.

| Ordem | Issue | Tipo | Depende de |
|-------|-------|------|------------|
| 22 | #29 Iniciar e finalizar partida ao vivo | Historia | #21 + #28 |
| 23 | #30 Atualizar placar ao vivo | Historia | #29 |

### ISSUE-017 — #29 Iniciar e finalizar partida (mesa)
**Como** mesa/delegado
**Quero** iniciar e finalizar uma partida pelo app
**Para** que o status apareca ao vivo para o publico

Criterios de aceitacao:
- [ ] Tela de operacao de jogo (autenticado)
- [ ] Botao iniciar: muda status para IN_PROGRESS
- [ ] Botao finalizar: muda status para FINISHED
- [ ] Confirmacao antes de finalizar

### ISSUE-018 — #30 Atualizar placar ao vivo
**Como** mesa/delegado
**Quero** atualizar o placar durante o jogo
**Para** que atletas e torcedores vejam em tempo real

Criterios de aceitacao:
- [ ] Botoes +1 para cada time
- [ ] Placar atualiza na tela do publico em ate 10 segundos
- [ ] Possibilidade de correcao de placar
- [ ] Historico de pontuacao

---

## Resumo por Release

| Release | Issues | Fases |
|---------|--------|-------|
| v0.1 — Foundation | #8 ao #23 | Fase 1 + Fase 2 + Fase 3 |
| v0.2 — Public Experience | #24 ao #28 | Fase 4 |
| v0.3 — Live Game | #29 e #30 | Fase 5 |