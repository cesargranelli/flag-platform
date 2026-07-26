# Flag Platform — Backlog Inicial

## Release 0.1 — Championship Foundation

### ISSUE-001 — Organization
**Como** organizador
**Quero** criar e gerenciar minha organizacao esportiva
**Para** que ela seja o ponto central de todos os meus campeonatos

Criterios de aceitacao:
- [ ] POST /api/v1/organizations — criar organizacao
- [ ] GET /api/v1/organizations/{id} — consultar organizacao
- [ ] PUT /api/v1/organizations/{id} — atualizar organizacao
- [ ] GET /api/v1/organizations — listar organizacoes
- [ ] Validacao: nome obrigatorio, slug unico
- [ ] Persistencia via Flyway
- [ ] API documentada no Swagger

### ISSUE-002 — Competition
**Como** organizador
**Quero** criar um campeonato dentro da minha organizacao
**Para** comecar a estruturar os jogos

Criterios de aceitacao:
- [ ] POST /api/v1/competitions
- [ ] GET /api/v1/competitions/{id}
- [ ] PUT /api/v1/competitions/{id}
- [ ] GET /api/v1/organizations/{id}/competitions
- [ ] Status: DRAFT, PUBLISHED, FINISHED
- [ ] API documentada no Swagger

### ISSUE-003 — Category
**Como** organizador
**Quero** criar categorias dentro de um campeonato (ex: Masculino 5x5, Feminino)
**Para** organizar os times por modalidade

Criterios de aceitacao:
- [ ] CRUD completo
- [ ] Associada a uma Competition
- [ ] API documentada

### ISSUE-004 — Venue
**Como** organizador
**Quero** cadastrar os campos onde os jogos acontecem
**Para** que atletas saibam onde jogar

Criterios de aceitacao:
- [ ] CRUD completo
- [ ] Campos: nome, endereco, link mapa (opcional)
- [ ] API documentada

### ISSUE-005 — Team
**Como** organizador
**Quero** cadastrar os times participantes
**Para** monta a tabela e os jogos

Criterios de aceitacao:
- [ ] CRUD completo
- [ ] Associado a uma Category
- [ ] Campos: nome, sigla, logo (opcional)
- [ ] API documentada

### ISSUE-006 — Round
**Como** organizador
**Quero** criar rodadas do campeonato
**Para** organizar os jogos em grupos/fases

Criterios de aceitacao:
- [ ] CRUD completo
- [ ] Associada a uma Category
- [ ] Campos: numero, nome, tipo (REGULAR, PLAYOFFS)
- [ ] API documentada

### ISSUE-007 — Game
**Como** organizador
**Quero** criar jogos dentro de uma rodada
**Para** publicar o calendario do campeonato

Criterios de aceitacao:
- [ ] CRUD completo
- [ ] Campos: homeTeam, awayTeam, venue, scheduledAt, round
- [ ] Status: SCHEDULED, IN_PROGRESS, FINISHED, CANCELLED
- [ ] API documentada

### ISSUE-008 — Game Result
**Como** mesa/delegado
**Quero** registrar o placar de um jogo
**Para** que o resultado fique disponivel publicamente

Criterios de aceitacao:
- [ ] POST /api/v1/games/{id}/result
- [ ] Campos: homeScore, awayScore
- [ ] Altera status do jogo para FINISHED
- [ ] Dispara recalculo da classificacao
- [ ] Requer autenticacao
- [ ] API documentada

### ISSUE-009 — Standing
**Como** atleta/torcedor
**Quero** ver a classificacao atualizada do campeonato
**Para** acompanhar quem esta na frente

Criterios de aceitacao:
- [ ] GET /api/v1/categories/{id}/standings
- [ ] Calculado automaticamente apos registro de resultado
- [ ] Ordenado por: pontos, saldo, pro, contra
- [ ] Campos por time: PJ, V, E, D, GP, GC, SG, PTS
- [ ] Sem autenticacao (publico)
- [ ] API documentada
