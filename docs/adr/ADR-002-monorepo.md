# ADR-002 — Monorepo

**Status:** Aceito
**Data:** 2026-07-26

## Contexto

O projeto é desenvolvido por um único desenvolvedor com stack backend (Spring Boot) e frontend (Flutter). É necessário decidir se os projetos ficam em repositórios separados ou em um único repositório.

## Decisão

Utilizar **monorepo**: backend, frontend, infraestrutura e documentação no mesmo repositório `cesargranelli/flag-platform`.

## Estrutura

`
flag-platform/
├── backend/
├── frontend/
├── infrastructure/
├── docs/
└── .ai/
`

## Justificativa

- Único histórico de commits para mudanças que afetam frontend e backend simultaneamente
- Menos overhead de gerenciamento de múltiplos repositórios
- Facilita rastreabilidade entre decisões de produto e implementação
- Adequado para projeto solo na fase atual

## Consequências

**Positivas:**
- Simplicidade operacional
- Facilidade para agentes de IA navegarem no código
- Um único PR pode incluir mudanças em todas as camadas

**Negativas:**
- Clone traz todo o conteúdo (baixo impacto neste estágio)
- Pode precisar de ajuste quando o time crescer

## Revisão

Esta decisão deve ser reavaliada caso o projeto tenha mais de 2 desenvolvedores simultâneos ou o frontend e backend precisem de ciclos de deploy completamente independentes.