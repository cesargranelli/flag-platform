# Flag Platform — Suíte E2E (Playwright)

Suíte de testes end-to-end do **Admin Web** (Flutter Web) contra o **staging
efêmero** levantado no GitHub Actions (postgres + backend Spring Boot na
`:8080` + build web servido na `:8081`). É a estratégia de qualidade da
issue #202 e vive **fora** do workspace Flutter/melos — nada aqui roda em
`flutter test`.

## Pré-requisitos

- Node.js 18+ (testado com v24)
- Stack de staging no ar (backend em `http://localhost:8080` e web em
  `http://localhost:8081`), ou a aplicação web apontando para o alvo via env.

## Instalação

```sh
cd e2e
npm install
npx playwright install chromium
```

## Rodando

```sh
npm test                 # roda toda a suíte (headless)
npm run test:headed      # roda com browser visível (debug)
npx playwright test --list   # lista os testes sem executar
```

## Variáveis de ambiente

| Variável                  | Default              | Descrição                                    |
| ------------------------- | -------------------- | -------------------------------------------- |
| `BASE_URL`                | `http://localhost:8081` | URL do Admin Web sob teste                |
| `E2E_RETRIES`             | `1`                  | Retries por teste                            |
| `E2E_WORKERS`             | `1`                  | Workers paralelos (CI usa shards via CLI)    |
| `E2E_ORGANIZER_EMAIL`     | `organizer@flag.test`| Credencial do organizador (seed staging)     |
| `E2E_ORGANIZER_PASSWORD`  | `Organizer@123`      | Senha do organizador (seed staging)          |

Exemplo (PowerShell):

```powershell
$env:BASE_URL="http://localhost:8081"; $env:E2E_ORGANIZER_EMAIL="organizer@flag.test"; $env:E2E_ORGANIZER_PASSWORD="Organizer@123"; npm test
```

## Cobertura atual

- `tests/login.spec.ts` — login válido (redireciona para a home) e login
  inválido (exibe "Email or password is invalid.").
- `tests/organization.spec.ts` — criação de organização pelo wizard de 5
  etapas (Identificação → Presidente → Contato → Localização → Identidade),
  com nome único por execução, e confirmação na listagem.

## Nota técnica: Flutter Web + Playwright

O Admin Web renderiza em CanvasKit: a UI é pintada em `<canvas>` e **não fica
no DOM**. Os testes habilitam a árvore de acessibilidade clicando no elemento
oculto `flt-semantics-placeholder` (helper `enableFlutterSemantics` em
`support/flutter.ts`) e então interagem pelos nós `flt-semantics`
(roles/aria-labels) com seletores `getByRole`/`getByText` e auto-wait.

## Relatórios e artefatos

- HTML em `playwright-report/` (abrir com `npx playwright show-report`).
- Trace/screenshot/vídeo de falhas em `test-results/` (retain-on-failure).
