# Documentação — Flag Platform

Índice da documentação técnica e de produto do monorepo.

## Arquitetura e fluxos

| Documento | Conteúdo |
|-----------|----------|
| [Visão geral da solução](architecture/overview.md) | O que é, arquitetura em camadas, componentes, fluxo ponta a ponta |
| [Mapa de componentes](architecture/components.md) | Catálogo do backend, frontend, infra e CI/CD |
| [Fluxos lógicos](architecture/logical-flows.md) | Diagramas Mermaid: conta/auth, cadastro, operação ao vivo, classificação, navegação, endpoints |
| [Papéis e autorização](architecture/roles-and-permissions.md) | Contexto de uso, roles, matriz de permissões, jornadas, segurança |

## Produto

| Documento | Conteúdo |
|-----------|----------|
| [Visão de produto](product/vision.md) | Problema, solução, aplicações, roadmap |

## Decisões de arquitetura (ADRs)

| Documento | Decisão |
|-----------|---------|
| [ADR-001 — Filosofia do Projeto](adr/ADR-001%20-%20Filosofia%20do%20Projeto.md) | Simplicidade e velocidade sobre arquitetura antecipada |
| [ADR-002 — Monorepo](adr/ADR-002-monorepo.md) | Backend, frontend, infra e docs no mesmo repositório |
| [ADR-003 — Modular Monolith](adr/ADR-003-modular-monolith.md) | Backend monolito modular Spring Boot; sem microsserviços/K8s |
| [ADR-004 — API First](adr/ADR-004-api-first.md) | Domínio → Banco → Service → API → Flutter; REST `/api/v1` |

## Design

| Documento | Conteúdo |
|-----------|----------|
| [Design tokens](design/tokens.md) | Fonte da verdade visual: cores Shifty, tipografia DM Sans, formas, componentes |
| [UX Admin Web — login](design/ux/admin-web-login.md) | Specs de UX das telas de autenticação |
| [Referências de UX](design/ux/referencias.md) | Referências de design |
| [Referências Figma](design/ux/figma-ref/) | Imagens de referência |

## Como ler esta documentação

Comece pelo [overview](architecture/overview.md) para o contexto geral e siga para [fluxos lógicos](architecture/logical-flows.md) para os diagramas de ponta a ponta. Consulte os [ADRs](adr/) para entender as decisões de arquitetura e as issues do GitHub para o planejamento.
