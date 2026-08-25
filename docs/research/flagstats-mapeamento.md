# Pesquisa — Mapeamento do FlagStats (app de referência)

> Pesquisa realizada em 2026-08-24 a partir do site oficial: https://site.flagstats.app/pt/
> Screenshots analisados: fluxo de scouting (`scouting.png`).

## Decisão de produto

As funcionalidades de **scouting/estatísticas** mapeadas abaixo deverão ser
hospedadas nos apps **Referee App** (coleta em campo) e **Public App**
(consumo de estatísticas/timeline pelo público) do Flag Platform.

## Modelo de negócio do FlagStats

- **PWA** (web app, sem loja de aplicativos) — navegador, instalável via "Adicionar à tela inicial"
- **SaaS por assinatura**: 30 dias grátis → Mensal R$59 · Semestral R$318 · Anual R$599
- Multi-dispositivo com sincronização automática, multi-acesso simultâneo, SSL + backups

## Fluxo de uso (4 passos)

1. Criar perfil do **time**
2. Cadastrar **atletas por posição**
3. Coletar dados de **jogos, amistosos e treinos**
4. Usar **timeline + dados** para decisões

## Funcionalidades anunciadas (seção `#feature-img`)

| # | Funcionalidade | Descrição |
|---|---|---|
| 1 | Simples de usar | Registrar jogadas em qualquer dispositivo, direto do navegador |
| 2 | Tempo real | Dados para atuar na sideline durante o jogo |
| 3 | Treinos | Monitorar performance também nos treinos |
| 4 | Dados do time | Decisões assertivas baseadas em dados |
| 5 | Histórico de atleta | Performance por campeonato/amistoso/treino |
| 6 | Estatísticas | Por campeonato, amistoso e por atleta |

## Tela-chave: scouting guiado (analisada via screenshot)

Fluxo de registro de jogada **pergunta por pergunta**, botões grandes, skip opcional:

```
"Qual é a tentativa?"   → [ 1ST ] [ TD ]
"Qual é a descida?"     → [ 1ª ] [ 2ª ] [ 3ª ] [ 4ª ]  + ↷ PULAR PERGUNTA
"Como foi a jogada?"    → [ PASSE ] [ CORRIDA ]        + ↷ PULAR PERGUNTA
                          [ ENCERRAR JOGADA ]  ← CTA primário
```

Padrão de UX: micro-formulário sequencial (1 pergunta por tela), toque único por
resposta, skip opcional — desenhado para uso na sideline sob pressão.

## Roadmap do FlagStats (sinais de mercado)

- **Em desenvolvimento**: timeline pública do jogo, card de status de atleta
  compartilhável, backup diário, Stripe
- **Backlog**: inteligência de jogo (predição de performance por situação),
  cadastro de jogadas do time, scouting de times adversários, escalação por
  jogo, apresentação gráfica de dados, multi-usuário, edição de jogadas na
  timeline, tempo extra, anotações (texto/áudio) na jogada, foto do atleta,
  exportar dados

## Comparação com o Flag Platform

| Capacidade | FlagStats | Flag Platform |
|---|---|---|
| Gestão (org/campeonato/divisões/times/atletas) | Básico | **Completo** |
| Placar ao vivo + timeline de eventos | Sim | Sim (Referee App) |
| Classificação/standings | — | Sim |
| Scouting guiado de jogadas (tentativa/descida/tipo) | **Core** | **Gap** |
| Estatísticas por atleta com histórico | **Core** | **Gap** |
| Treinos como tipo de coleta | Sim | **Gap** |
| Exportar dados / gráficos | Backlog | Gap |

## Insights

1. Posicionamento FlagStats: **coleta tática de jogadas + analytics por atleta**.
   Posicionamento Flag Platform: **gestão de campeonatos ponta-a-ponta** — complementares.
2. Gaps naturais para o Flag Platform (futuro, nos apps Referee/Public):
   scouting guiado, tipologia de jogada como dado estruturado, estatísticas por
   atleta com histórico comparativo, treinos como categoria de coleta,
   exportação de dados.
