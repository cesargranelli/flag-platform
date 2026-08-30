# AGENTS.md — Flag Platform

## Working Agreement

- **Branching model: GitFlow padrão.**
    - `main`: produção — recebe apenas merges de `release/*` e `hotfix/*` (deploy roda aqui).
    - `develop`: integração — todas as features partem dela e retornam para ela via PR.
    - Features: `feature/issue-{n}-{slug}` (a partir de `develop`, PR → `develop`).
    - Releases: `release/vX.Y` (de `develop`, PR → `main` **e** de volta para `develop`).
    - Hotfixes: `hotfix/{descricao}` (de `main`, PR → `main` **e** de volta para `develop`).
    - Excluir a branch-feature após o merge (inclui a remota: `git push origin --delete <branch>`).
- For each stage/feature we work on, **remove all tests written in frontend and backend** (no automated test files are kept).
- Quality will be guaranteed by another strategy (decided by the user), not by automated tests. Do not add, keep, or restore test files unless the user explicitly asks. A estratégia vigente é a suíte E2E Playwright em `e2e/` contra staging efêmero (ADR-005) — ela é a única exceção; não confundi-la com testes unitários/de widget.
- **Never merge locally.** The flow is always: push the feature branch → open a PR on GitHub (base `develop`, ou `main` apenas para release/hotfix) → the tech-lead agent reviews and approves the PR → merge via GitHub (`gh pr merge`). Local branches only sync from their remote after the merge.
- **Local commands need no permission** while working inside the flag-platform project: compile, analyze, run checks, git status/add/commit/push to working branches, create issues/PRs via `gh`, etc., are executed autonomously. Ask only when an action leaves the project directory or affects global/external configuration.
- **CI indisponível (GitHub Actions fora/limite).** Se o CI do GitHub não disparar para o PR (ex.: limite mensal de uso do Actions ou indisponibilidade) e a mudança tiver sido validada localmente (`melos analyze` para frontend / `.\mvnw.cmd --batch-mode -DskipTests compile` para backend, conforme o escopo), o tech-lead pode **aprovar/mergear o PR sem os checks**, desde que TODAS as condições abaixo sejam atendidas:
    1. a branch base (`develop` ou `main`) **não** tenha required status checks configurados;
    2. o escopo da mudança **não dependa** do job que não rodou (ex.: mudança frontend-only não exige o job backend, e vice-versa);
    3. a ocorrência seja **registrada explicitamente no reporte ao usuário** (e, se houver, no construtor/issue).
    Se alguma condição falhar ou houver dúvida, **pausar e acionar o usuário** para decidir (não mergear às cegas).

## Fluxo de issues (GitHub)

- Toda issue atribuída (assignee) a **`cesargranellidev`**; escopos mistos viram **uma issue por subagente** (backend/frontend/app/devops/dba — labels do escopo). Issues de banco/migrations vão para o subagente `dba` (`.opencode/agent/dba.md`).
- O corpo da issue referencia a branch: `**Branch:** \`feature/issue-{n}-{slug}\``. Issue só fecha após o merge da branch.
- Não implementar feature sem issue formalizada; commits no padrão `feat(#n): ...` / `fix(#n): ...`.

## Layout do monorepo

| Diretório | Conteúdo |
|---|---|
| `backend/` | Spring Boot 4.1 / **Java 25**, Maven wrapper, PostgreSQL + Flyway |
| `frontend/` | Workspace Flutter (**pub workspace + melos**): apps `admin_web` (web), `public_app` e `referee_app` (mobile); packages `api`, `core`, `domain` |
| `e2e/` | Suíte Playwright (Node) — independente do Flutter/melos |
| `infrastructure/docker/` | docker-compose com Postgres 16 (pgadmin só no profile `tools`) |

## Comandos

Backend (em `backend/`; no Windows use `.\mvnw.cmd`):

```powershell
.\mvnw.cmd --batch-mode -DskipTests compile     # o que o CI roda
.\mvnw.cmd spring-boot:run                      # requer Postgres no ar (perfil default já aponta p/ localhost:5432)
```

Frontend (a partir de `frontend/`; após clonar, rodar `melos bootstrap`):

```sh
melos bootstrap   # liga os packages do workspace
melos analyze     # flutter analyze em todos os packages (o que o CI roda)
cd apps/admin_web && flutter run   # cada app roda pelo próprio diretório
```

Infra e E2E:

```sh
docker compose -f infrastructure/docker/docker-compose.yml up -d   # Postgres flagplatform/flagplatform@localhost:5432
cd e2e && npm ci && npx playwright install chromium && npm test    # exige backend :8080 + web :8081 no ar
```

## Backend

- Módulos (estilo Modulith) ficam direto em `br.com.flagplatform.{modulo}` (`athlete`, `competition`, `conference`, `division`, `game`, `organization`, `roster`, `round`, `standing`, `team`, `user`, `venue`, `checkin`, `common`...), cada um com `controller/dto/entity/mapper/repository/service(/exception)`. Entrypoint: `FlagPlatformApplication`.
- **Toda alteração de schema via nova migration Flyway** `V{n}__descricao.sql` em `src/main/resources/db/migration` (hoje até V30 — conferir o maior número antes de criar). Migration estruturante em tabelas relacionadas deve vir acompanhada de script de reset (TRUNCATE) — dados de dev são descartáveis (#319).
- API REST versionada em `/api/v1`, JWT Bearer com roles ADMIN/ORGANIZER/MESA; paginação via `page`/`size` com total no header `X-Total-Count`; endpoints documentados com OpenAPI (Swagger UI em `/swagger-ui.html`). Porta 8080; schema do banco: `platform`.
- Configs sensíveis vêm de env: `JWT_SECRET`, `JWT_EXPIRATION_SECONDS`, `LOGIN_MAX_ATTEMPTS`, `MAIL_ENABLED` etc. (ver `application.yml`).
- Perfil `staging`: `StagingDataSeeder` semeia o organizador usado pela suíte E2E (`organizer@flag.test` / `Organizer@123`).

## Frontend

- Packages têm prefixo `flag_` (`flag_api`, `flag_core`, `flag_domain`, `flag_admin_web`...); apps consomem a API pelo package `api` (dio).
- Config de ambiente via dart-define (lida em `packages/core/lib/src/config/app_config.dart`): `API_BASE_URL` (default `http://localhost:8080`) e `ENVIRONMENT` (ex.: staging usa `--dart-define=API_BASE_URL=http://localhost:8080 --dart-define=ENVIRONMENT=staging`).

## CI/CD (`.github/workflows/`)

- `ci.yml` — required check de PR: backend compile + frontend melos analyze. Nada de testes aqui (ver Working Agreement).
- `staging-e2e.yml` — sobe stack completa (postgres + JAR com perfil staging + Admin Web na :8081) e roda Playwright em 2 shards; dispara em push para `main` ou manual; **não é** required check de PR.
- `release.yml` — empacota o JAR e faz deploy ao chegar em `main` (paths `backend/**`/`infrastructure/**`); deploy real depende da environment "production" (gate de aprovação).

## Fontes de verdade e armadilhas

- Leia antes de agir: `.ai/project-context.md` (domínio + regras de issue), `.ai/workflow-memory.md` (estado atual), ADRs em `docs/adr/`, design tokens em `docs/design/tokens.md`.
- **Cuidado**: partes de `.ai/project-context.md` e do `README.md` estão defasadas (dizem Java 21/Spring Boot 3.x, módulos em `modules/{nome}/`, entidade Category). Confie no `pom.xml` (Java 25 / Boot 4.1), no código (módulos em pacotes de primeiro nível; categorias foram substituídas por modalidade como enum da competition — V24/V26/V30) e nos workflows.
- **Flyway "checksum mismatch" (armadilha)**: a convenção de reset (#319/#321) permite editar migrations já aplicadas, mas isso muda o checksum e o Flyway **falha ao iniciar** com `Migration checksum mismatch for migration version N` (o log traz `Applied to database` vs `Resolved locally`). Reparo padrão: `flyway repair` (atualiza o checksum em `flyway_schema_history`); sem o CLI, rode `UPDATE platform.flyway_schema_history SET checksum = <valor "Resolved locally"> WHERE version = 'N';`. Dados de dev são descartáveis — alternativa: dropar o schema `platform` e re-migrar de zero.
- Flutter Web renderiza em CanvasKit (UI fora do DOM): testes E2E precisam habilitar semântica clicando em `flt-semantics-placeholder` — usar o helper `enableFlutterSemantics` de `e2e/support/flutter.ts`.
