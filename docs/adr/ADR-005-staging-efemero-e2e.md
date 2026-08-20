# ADR-005 — Staging efêmero com testes E2E (quality gate pré-produção)

**Status:** Aceito
**Data:** 2026-08-19

## Contexto

O CI roda build + testes (backend e frontend) e o `release.yml` publica direto na
`environment: production` (com gate de aprovação manual). Não havia camada de
validação E2E pesada contra um ambiente que espelhasse produção antes do deploy
final — falhas de integração (layout, fluxo real de UI, comunicação com a API)
só seriam descobertas em produção.

## Decisão

Criar um **ambiente de staging efêmero dentro do GitHub Actions** que sobe uma
stack completa (postgres + backend Spring Boot + build web do Admin Web), roda
uma **suíte E2E Playwright** e derruba tudo ao final. A suíte é a **estratégia
de qualidade** do projeto (substitui testes automatizados de frontend/backend,
conforme Working Agreement) e funciona como **quality gate**: se passar, o
artefato é considerado estável para promoção; se falhar, a ida para produção é
barrada sem impacto para o usuário final.

### Decisões de escopo (issue #202)

- **Staging efêmero no GitHub Actions**: o runner sobe postgres (service
  container), backend (`java -jar` com perfil `staging`) e web (servidor
  estático na porta 8081). Zero infra fixa; o teardown é automático ao fim do job.
- **Alvo dos E2E: Admin Web** — login do organizador (válido/inválido) e criação
  de organização. (Campeonato adiado: havia feature de competição em
  desenvolvimento paralelo.)
- **Deploy de produção segue manual e desacoplado do merge de PR**: o workflow
  `staging-e2e.yml` roda de forma independente (não é required check do CI) e
  não bloqueia o desenvolvimento. O `release.yml` permanece com a environment
  `production` e aprovação manual.

## Arquitetura

```
push main / workflow_dispatch
        │
        ▼
  job build ──► backend jar + build web (admin_web)
        │
        ▼
  job staging-e2e (matrix de shards)
        │  service: postgres:16-alpine
        │  java -jar <jar> --spring.profiles.active=staging
        │  python3 -m http.server 8081 --directory <build web>
        │  npx playwright test --shard=N/2
        │
        ├── verde ──► artefato estável → promoção para produção (manual)
        └── vermelho ──► falha → produção bloqueada; relatório/traces publicados
```

- **Seed de staging**: `StagingDataSeeder` (`@Profile("staging")`) cria usuários
  com status `ACTIVE` (registro público gera `PENDING`). Organizador
  `organizer@flag.test` / `Organizer@123` e admin `admin@flag.test` / `Admin@123`.
- **Flutter Web + Playwright**: o Admin Web renderiza em CanvasKit (UI no
  canvas, fora do DOM). A suíte habilita a árvore de acessibilidade (semantics)
  via `flt-semantics-placeholder` e interage por roles/aria-labels com
  auto-wait (`e2e/support/flutter.ts`).

## Justificativa

- Testes E2E pesados consomem muita máquina; rodá-los em pré-produção efêmera
  permite instâncias temporárias/menores e custo zero quando ocioso.
- Dados de teste poluem apenas o banco efêmero do runner (reset automático).
- Risco zero para o usuário final: falhas são capturadas antes de qualquer
  cliente perceber.
- Parallelização gratuita do Playwright via shards no GitHub Actions.

## Consequências

**Positivas:**
- Camada real de validação de integração (login + fluxo de cadastro no Admin Web)
- Custo de infra baixo (efêmero, sem ambiente fixo)
- Deploy de produção desacoplado do desenvolvimento (não bloqueia o fluxo)

**Negativas:**
- Tempo de execução do workflow (download de browsers, bootstrap, shards) — os
  artefatos de report/traces ajudam no diagnóstico de falha
- Cobertura atual limitada ao Admin Web (login + organização); campeonato fica
  para evolução quando a feature de competição estabilizar

## Alternativas consideradas

- **Cypress**: paralelização paga, mais pesado no CI — preterido.
- **Selenium**: menos integrado com o ecossistema Playwright — preterido.
- **Ambiente de staging persistente (VPS/Fly)**: custo de infra fixa, desnecessário
  no estágio atual — preterido em favor do efêmero.

## Referências

- Issue #202 (tarefa) — implementação do staging efêmero + E2E
- Working Agreement (`AGENTS.md`) — qualidade por estratégia, sem testes
  automatizados de frontend/backend
- `e2e/` — suíte Playwright; `.github/workflows/staging-e2e.yml` — workflow
