# Working Agreement

- For each stage/feature we work on, **remove all tests written in frontend and backend** (no automated test files are kept).
- Quality will be guaranteed by another strategy (decided by the user), not by automated tests. Do not add, keep, or restore test files unless the user explicitly asks.
- **Never merge locally.** The flow is always: push the feature branch → open a PR on GitHub → the tech-lead agent reviews and approves the PR → merge via GitHub (`gh pr merge`). The local `main` only syncs from `origin/main` after the merge.
- **Local commands need no permission** while working inside the flag-platform project: compile, analyze, run checks, git status/add/commit/push to feature branches, create issues/PRs via `gh`, etc., are executed autonomously. Ask only when an action leaves the project directory or affects global/external configuration.
