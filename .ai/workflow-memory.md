# Flag Dev Workflow — Estado do Projeto (memória)

> Atualizado pelo tech-lead. Regras vigentes além deste arquivo:

## Regras do projeto (ver `.ai/project-context.md` e `AGENTS.md`)
1. Issues assinadas a `cesargranellidev`; uma issue por subagente/escopo; corpo referencia a branch `issue-{n}-{slug}`.
2. Merge **somente via PR no GitHub** (nunca local); tech-lead revisa/aprova; main local sincroniza depois.
3. Autonomia total em comandos locais dentro do projeto.
4. **Excluir a branch-feature remota após o merge** (`git push origin --delete <branch>`).
5. Sem arquivos de teste automatizado (AGENTS.md).

## Referência de design
- Figma Shifty: https://www.figma.com/design/MxhoZOwT1HrI1Zrm3Vdc7M/Shifty---House-Service-App--Community-?node-id=5-0&t=LdacgMtgKolC4XVk-0
- Registrado também em `docs/design/tokens.md`.

## Decisões de domínio registradas
- Autorização futura: **ADMIN tem acesso full** (override de qualquer trava, incluindo edição por criador).

## Fila ativa
- Vazia — issues #273 e #230 encerradas a pedido do usuário (2026-08-24).
- Pedidos pendentes de re-priorização (não formalizados): autorização por criador de campeonato; calendário vs Figma; fluxo de criação; conferências/divisões na edição + modais + botão rodadas.
