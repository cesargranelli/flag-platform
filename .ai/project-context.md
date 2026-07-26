# Flag Platform — Project Context

## Objetivo

Construir uma plataforma configurável para organizações de Flag Football
gerenciarem campeonatos e oferecerem uma experiência moderna para atletas,
organizadores e torcedores.

O projeto nasce de uma **dor real**: aplicativo atual com baixa qualidade,
site inoperante, dificuldade de consulta de informações e acompanhamento
de jogos. O criador é um atleta que joga Flag Football em São Paulo.

## Visão

> "O melhor lugar para acompanhar um campeonato de flag."

Não criar um ERP esportivo. Criar algo simples, útil e utilizável.

## Primeiro Cliente

**APFA — Associação Paulista de Futebol Americano**

## Primeiro Campeonato Alvo

- Flag Football 5x5 Masculino
- Aproximadamente 30 equipes
- Fase de grupos + playoffs

## Papel deste Agente

Você é o **desenvolvedor executor**.

Antes de implementar qualquer coisa:

1. Leia este arquivo
2. Leia todos os ADRs em `docs/adr/`
3. Respeite as decisões existentes
4. Não crie abstrações sem necessidade
5. Pergunte quando houver dúvida de domínio

## MVP — Funcionalidades

### Para o Organizador
- Criar organização
- Criar campeonato
- Criar categoria (ex: Flag 5x5 Masculino)
- Cadastrar campos/venues
- Cadastrar times
- Criar rodadas e jogos
- Publicar campeonato

### Para a Mesa / Delegado (requer login)
- Iniciar partida
- Atualizar placar
- Finalizar partida

### Para o Público / Atletas (sem login)
- Consultar calendário de jogos
- Acompanhar resultados
- Visualizar classificação
- Ver detalhes do jogo

## Fora do MVP

- Cadastro de atletas / roster
- Estatísticas por jogada / scout
- Streaming / transmissão
- Ranking avançado histórico
- Perfil de atleta

## Modelo de Domínio (MVP)

`
Organization
  └── Competition
        └── Category
              ├── Venue (campo)
              ├── Team
              └── Round
                    └── Game
                          └── Standing (calculado)
`

## Stack

### Backend
- Java 21
- Spring Boot 3.x
- Spring Data JPA + Spring Validation + Spring Security
- PostgreSQL (schema: `platform`)
- Flyway (migrações)
- SpringDoc OpenAPI (Swagger)

### Frontend
- Flutter (mobile + web)

### API
- REST — versionamento: `/api/v1`

## Organização de Cada Módulo Backend

`
modules/{nome}/
├── controller/
├── service/
├── repository/
├── entity/
├── dto/
├── mapper/
└── validation/
`

## Regras de Desenvolvimento

### FAZER
- Funcionalidades que resolvam a dor do atleta ou do organizador
- Commits pequenos e descritivos
- Testes nos serviços principais
- Documentar API com OpenAPI
- Usar Flyway para todas alterações de schema

### NÃO FAZER
- Microsserviços / Kubernetes / Kafka
- CQRS / Event Sourcing
- Abstrações antecipadas

## Pergunta Principal

> "Isso ajuda uma organização de Flag Football a realizar um campeonato melhor?"

Se a resposta for não, fica fora do MVP.

## Autenticação

- **Público**: sem login
- **Mesa / Delegado**: login obrigatório
- **Organizador**: login obrigatório
- **Atleta**: opcional (fase futura)