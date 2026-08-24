# Working Agreement

- **Branching model: GitFlow padrão.**
    - `main`: produção — recebe apenas merges de `release/*` e `hotfix/*` (deploy roda aqui).
    - `develop`: integração — todas as features partem dela e retornam para ela via PR.
    - Features: `feature/issue-{n}-{slug}` (a partir de `develop`, PR → `develop`).
    - Releases: `release/vX.Y` (de `develop`, PR → `main` **e** de volta para `develop`).
    - Hotfixes: `hotfix/{descricao}` (de `main`, PR → `main` **e** de volta para `develop`).
    - Excluir a branch-feature após o merge.
- For each stage/feature we work on, **remove all tests written in frontend and backend** (no automated test files are kept).
- Quality will be guaranteed by another strategy (decided by the user), not by automated tests. Do not add, keep, or restore test files unless the user explicitly asks.
- **Never merge locally.** The flow is always: push the feature branch → open a PR on GitHub (base `develop`, ou `main` apenas para release/hotfix) → the tech-lead agent reviews and approves the PR → merge via GitHub (`gh pr merge`). Local branches only sync from their remote after the merge.
- **Local commands need no permission** while working inside the flag-platform project: compile, analyze, run checks, git status/add/commit/push to working branches, create issues/PRs via `gh`, etc., are executed autonomously. Ask only when an action leaves the project directory or affects global/external configuration.
