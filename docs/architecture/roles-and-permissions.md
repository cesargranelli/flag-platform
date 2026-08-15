# Flag Platform — Papéis, Contexto e Autorização

Como cada ator usa a plataforma, quais papéis existem e o que cada um pode fazer na API.

## Contexto de uso (por que a plataforma existe)

Comunidade de Flag Football no Brasil. As informações estão hoje espalhadas em PDF, Instagram, WhatsApp e planilhas; o app oficial tem baixa qualidade e o site é inoperante. A Flag Platform reúne tudo em um lugar: **calendário, resultados, classificação, elenco, mapa do campo e operação ao vivo**, com padrão único entre organizações.

## Papéis de sistema

### Backend — roles (enum `UserRole`)

| Role | Uso | Criação |
|------|-----|---------|
| **ADMIN** | Super usuário: aprova contas, gerencia usuários | Via seed/ADMIN |
| **ORGANIZER** | Gestão de conteúdo do campeonato | Registro público (PENDING) ou ADMIN |
| **MESA** | Operação ao vivo da partida (placar, check-in) | Somente ADMIN |

### Status de conta (enum `UserStatus`)

```
PENDING ─► ACTIVE
   │
   └──► REJECTED
```

- Registro público → **PENDING** até aprovação de um ADMIN.
- Conta ADMIN/ORG criada por ADMIN → já **ACTIVE**.
- `login` exige `ACTIVE` (senão 403).

## Matriz de permissões (API)

Expressões centralizadas em `SecurityExpressions` (SpEL) e aplicadas via `@PreAuthorize`.

| Operação | ADMIN | ORGANIZER | MESA | Público |
|----------|:-----:|:---------:|:----:|:-------:|
| **CRUD de conteúdo** (organização, campeonato, categoria, campo, time, rodada, jogo, atleta, roster) | ✅ | ✅ | ❌ | ❌ |
| **Leitura pública** (listas/detalhes de todos os domínios) | ✅ | ✅ | ✅ | ✅ |
| **Operação ao vivo** (status do jogo, resultado, pontos, corrigir placar) | ✅ | ❌ | ✅ | ❌ |
| **Check-in e validação de atletas** | ✅ | ❌ | ✅ | ❌ |
| **Gestão de usuários** (criar, listar, aprovar, rejeitar) | ✅ | ❌ | ❌ | ❌ |
| **Login / registro / recuperação de senha** | ✅ | ✅ | ✅ | ✅ (público) |
| **`GET /games/{id}/checkin`** (regra especial) | ✅ | ❌ | ✅ | ❌ |

**Aplicação por tela:**

- Admin Web mostra **Aprovações** e **Usuários** apenas para `ADMIN` (cards da home variam por role).
- Referee App opera jogos com role `MESA` (ou `ADMIN`).

## Jornadas por papel

### Organizador (Admin Web)

```mermaid
flowchart LR
    A[Cadastra conta<br/>aguarda aprovação] --> B[Login]
    B --> C[Home: cards]
    C --> D[Cria organização]
    D --> E[Publica campeonato]
    E --> F[Estrutura: categorias,<br/>campos, times, rodadas, jogos]
    F --> G[Cadastra atletas e elencos]
```

**Resultado esperado**: manter o campeonato atualizado em poucos cliques, sem planilhas/PDF/WhatsApp.

### Mesa / Delegado (Referee App)

```mermaid
flowchart LR
    A[Conta criada pelo ADMIN<br/>role MESA] --> B[Login no celular]
    B --> C[Escolhe jogo]
    C --> D[Pré-jogo: check-in dos atletas]
    D --> E[Inicia a partida]
    E --> F[Atualiza placar ao vivo]
    F --> G[Finaliza]
```

**Resultado esperado**: operar a partida em menos de 30 segundos — iniciar, placar, validar atletas, finalizar.

### Atleta / Torcedor (Public App — sem login)

```mermaid
flowchart LR
    A[Abre o app] --> B[Lista de campeonatos]
    B --> C[Calendário de jogos]
    B --> D[Resultados recentes]
    B --> E[Classificação]
    C --> F[Detalhe do jogo:<br/>placar ao vivo, local, mapa]
```

**Resultado esperado**: saber tudo sobre o campeonato — próximo jogo, campo, adversário, placar e classificação.

## Segurança transversal

- **JWT HS256** (stateless) injetado por `JwtAuthenticationFilter`; expiração configurável (`app.jwt.expiration-seconds`, default 3600s).
- **Rate limit** no login: `LoginRateLimitFilter` (10 tentativas / 300s por IP → 429).
- **Token de reset de senha**: armazenado com hash SHA-256, expira em 60min, uso único (`usedAt`); anti-enumeração (não revela se o e-mail existe).
- **Senhas**: BCrypt.
- **Erros de API**: `ApiException` → RFC-7807 (`ProblemDetail`) com status HTTP coerente (400/401/403/404/409/429).
- **CORS**: liberado para `localhost:*` em dev (Flutter Web) + origens configuráveis.

## Modelo de domínio (visão geral)

| Entidade | Tabela | FK |
|----------|--------|-----|
| Organization | `organizations` | — |
| Competition | `competitions` | organization_id |
| Category | `categories` | competition_id |
| Venue | `venues` | organization_id |
| Team | `teams` | category_id |
| Round | `rounds` | category_id |
| Game | `games` | round_id, home_team_id, away_team_id, venue_id |
| ScoreEvent | `score_events` | game_id, team_id |
| Standing | `standings` | category_id, team_id |
| Athlete | `athletes` | — |
| RosterEntry | `team_roster` | team_id, athlete_id |
| CheckIn | `checkins` | game_id, team_id, athlete_id |
| User | `users` | — |
| PasswordResetToken | `password_reset_tokens` | user_id |
