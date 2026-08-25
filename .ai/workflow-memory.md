# Flag Dev Workflow — Estado do Projeto (memória)

> Atualizado pelo tech-lead. Regras vigentes além deste arquivo:

## Regras do projeto (ver `.ai/project-context.md` e `AGENTS.md`)
1. **GitFlow padrão**: `main` (produção, só release/hotfix) · `develop` (integração) · `feature/issue-{n}-{slug}` (de develop → develop) · `release/vX.Y` · `hotfix/*`.
2. Issues assinadas a `cesargranellidev`; uma issue por subagente/escopo; corpo referencia a branch-feature.
3. Merge **somente via PR no GitHub** (nunca local); PRs de feature têm base **`develop`**; tech-lead revisa/aprova.
4. Autonomia total em comandos locais dentro do projeto.
5. **Excluir a branch remota após o merge** (`git push origin --delete <branch>`).
6. Sem arquivos de teste automatizado (AGENTS.md).

## Referência de design
- Figma Shifty: https://www.figma.com/design/MxhoZOwT1HrI1Zrm3Vdc7M/Shifty---House-Service-App--Community-?node-id=5-0&t=LdacgMtgKolC4XVk-0
- Registrado também em `docs/design/tokens.md`.

## Decisões de domínio registradas
- Autorização futura: **ADMIN tem acesso full** (override de qualquer trava, incluindo edição por criador).

## Fila ativa
- **VAZIA** (2026-08-24) — nenhuma issue ou PR aberto.
- Histórico: pedidos anteriores (autorização por criador, calendário vs Figma, fluxo de criação, conferências/divisões na edição, botão rodadas) foram arquivados sem formalização por decisão do usuário; podem ser retomados sob demanda.
