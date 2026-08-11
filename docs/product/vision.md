# Flag Platform — Visao de Produto

## O Problema

A comunidade de Flag Football no Brasil sofre com:

- Aplicativo oficial com baixa qualidade
- Site inoperante
- Informacoes espalhadas em PDF, Instagram, WhatsApp e planilhas
- Dificuldade de acompanhar resultados e classificacao em tempo real
- Sem padrao entre organizacoes

## A Solucao

Uma plataforma unica onde qualquer organizacao pode:

- Criar e gerenciar campeonatos
- Divulgar jogos e resultados
- Oferecer uma experiencia moderna para atletas e torcedores

## Aplicacoes (3 Clientes)

| App | Plataforma | Usuario | Login |
|-----|-----------|---------|-------|
| **Public App** | Flutter mobile | Atletas / Torcedores | Nao |
| **Referee App** | Flutter mobile | Mesa / Delegado | Sim |
| **Admin Web** | Flutter Web | Organizador | Sim |

### Organizador (Admin Web)
Responsavel por criar e gerenciar o campeonato. Usa a aplicacao web para manter todos os cadastros: organizacao, campeonato, categorias, campos, times, rodadas, jogos, atletas e rosters. Sem planilhas, sem PDF, sem grupo de WhatsApp.

### Mesa / Delegado (Referee App)
Opera as partidas no dia do jogo pelo celular: inicia o jogo, atualiza o placar, valida os atletas no pre-jogo e durante a partida, e finaliza — em menos de 30 segundos.

### Atleta / Publico (Public App)
Quer abrir o celular e saber tudo sobre o campeonato: proximo jogo, campo, adversario, placar e classificacao. Sem login.

## Experiencia Desejada (Publico)

Tela inicial:
- Nome do campeonato
- Proximos jogos
- Resultados recentes
- Tabela de classificacao

Pagina do jogo:
- Times, placar, campo, horario, status
- Classificacao atual
- Historico de confrontos
- Validacao de atletas (mesa, durante o jogo)

## MVP — Criterio de Sucesso

Em ate 8 semanas, entregar uma aplicacao em que:

1. Qualquer atleta consiga acompanhar um campeonato completo (calendario, resultados, classificacao)
2. Qualquer organizador consiga manter essas informacoes atualizadas em poucos cliques pela web
3. A mesa valide os atletas no pre-jogo e durante a partida, e atualize o placar ao vivo

## Roadmap

### Release 0.1 — Championship Foundation
Backend completo para criar e operar um campeonato:
Organization, Competition, Category, Venue, Team, Round, Game, Standing

### Release 0.2 — Cadastros + Public Experience
- Autenticacao e autorizacao (JWT, roles)
- Atletas e rosters (TeamRoster/Athlete)
- Admin Web (Flutter Web) para gestao de cadastros
- Public App (Flutter) para acompanhamento do campeonato

### Release 0.3 — Live Game + Validacao
- Referee App (Flutter): operacao ao vivo com placar em tempo real
- Validacao de atletas (CheckIn) no pre-jogo e durante a partida

### Fase 2 — Perfil dos Times
Logo, uniforme, redes sociais, historia

### Fase 3 — Perfil do Atleta
Numero, posicao, foto, time atual, historico

### Fase 4 — Scout da Partida
TD, INT, Sack, Flag, Conversao, MVP

### Fase 5 — Estatisticas Historicas
Maior pontuador, maior defensor, ranking, historico de confrontos

## Diferencial

O diferencial nao sao as estatisticas. E a experiencia.

Hoje a informacao esta espalhada. A plataforma reune tudo em um lugar:
calendario, resultados, classificacao, elenco, mapa do campo e transmissao.
