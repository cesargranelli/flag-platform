# ADR-004 — API First

**Status:** Aceito
**Data:** 2026-07-26

## Contexto

Com backend Spring Boot e frontend Flutter, e necessario definir a estrategia de desenvolvimento e contrato entre as camadas.

## Decisao

Adotar **API First**: o desenvolvimento segue a ordem:

Dominio -> Banco (Flyway) -> Service -> API REST -> Flutter

A API e documentada via **SpringDoc OpenAPI (Swagger UI)** e serve como contrato para o frontend.

## Especificacoes

- Protocolo: REST
- Versionamento: /api/v1
- Formato: JSON
- Autenticacao: Bearer Token (JWT)
- Documentacao: Swagger UI disponivel em /swagger-ui.html

## Justificativa

- O Flutter consome a API REST — o contrato precisa ser estavel e documentado
- API First evita que mudancas de UI quebrem o backend
- Facilita uso por agentes de IA que podem ler o contrato OpenAPI
- Permite futura expansao (app web, integracoes externas)

## Consequencias

**Positivas:**
- Contrato claro entre frontend e backend
- Documentacao sempre atualizada (gerada do codigo)
- Facilita testes de integracao

**Negativas:**
- Requer disciplina para manter DTOs separados das entidades
- Pequeno overhead no design de cada endpoint
