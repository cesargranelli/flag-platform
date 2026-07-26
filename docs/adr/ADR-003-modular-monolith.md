# ADR-003 — Modular Monolith

**Status:** Aceito
**Data:** 2026-07-26

## Contexto

É necessário definir a arquitetura do backend. As opções principais são: monolito simples, modular monolith ou microsserviços.

## Decisão

Utilizar **Modular Monolith** com Spring Boot.

## Estrutura de Pacotes

`
br.com.flagplatform
├── common/          # utilitários, exceções, paginação
├── config/          # configurações Spring (CORS, OpenAPI, etc.)
├── security/        # autenticação e autorização
└── modules/
    ├── organization/
    ├── competition/
    ├── category/
    ├── team/
    ├── venue/
    ├── round/
    ├── game/
    └── standing/
`

Cada módulo contém:

`
{modulo}/
├── controller/
├── service/
├── repository/
├── entity/
├── dto/
├── mapper/
└── validation/
`

## Justificativa

- Microsserviços adicionam complexidade operacional incompatível com projeto solo
- Modular monolith permite organização clara com baixo overhead
- Permite extração futura de módulos para microsserviços se necessário
- Spring Boot é familiar e produtivo para Java

## Consequências

**Positivas:**
- Deploy simples (um único artefato)
- Desenvolvimento rápido
- Fácil debugging e rastreamento
- Sem necessidade de orquestração (Kubernetes, service mesh)

**Negativas:**
- Escalar partes individuais exige escalar o todo
- Módulos compartilham o mesmo processo JVM

## O que NÃO será usado

- Microsserviços
- Kubernetes
- Kafka / RabbitMQ
- CQRS / Event Sourcing
- Redis (nesta fase)