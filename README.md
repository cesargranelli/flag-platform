# Flag Platform

> A melhor plataforma para acompanhar um campeonato de Flag Football.

## Sobre

O Flag Platform nasceu de uma dor real: o aplicativo e o site oficiais do Flag Football no Brasil sao ruins ou inoperantes. Este projeto visa criar uma plataforma aberta, moderna e facil de usar para organizadores e atletas.

**Primeiro cliente:** APFA — Associacao Paulista de Futebol Americano

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Backend | Java 21 + Spring Boot 3.x |
| Banco | PostgreSQL + Flyway |
| Frontend | Flutter |
| API | REST / OpenAPI |
| Infra | Docker Compose |

## Estrutura do Repositorio

``nflag-platform/
├── .ai/                    # Contexto para agentes de IA
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── backend/                # Spring Boot
├── frontend/               # Flutter
├── infrastructure/
│   └── docker/             # Docker Compose
└── docs/
    ├── adr/                # Decisoes arquiteturais
    ├── product/            # Visao e backlog
    └── diagrams/
`\n
## Documentacao

- [Visao do Produto](docs/product/vision.md)
- [Backlog](docs/product/backlog.md)
- [ADR-001 - Filosofia do Projeto](docs/adr/ADR-001%20-%20Filosofia%20do%20Projeto.md)
- [ADR-002 - Monorepo](docs/adr/ADR-002-monorepo.md)
- [ADR-003 - Modular Monolith](docs/adr/ADR-003-modular-monolith.md)
- [ADR-004 - API First](docs/adr/ADR-004-api-first.md)
- [Contexto do Projeto (.ai)](. ai/project-context.md)

## MVP

O MVP permite que um campeonato completo seja organizado e acompanhado:

- Organizador cria campeonato, times, rodadas e jogos
- Mesa registra resultados das partidas
- Atletas acompanham calendario, resultados e classificacao **sem login**

## Como Rodar (em breve)

`ash
# Infraestrutura
docker-compose -f infrastructure/docker/docker-compose.yml up -d

# Backend
cd backend
./mvnw spring-boot:run

# Frontend
cd frontend
flutter run
`\n
## Licenca

MIT
