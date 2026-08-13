package br.com.flagplatform.game;

import br.com.flagplatform.common.enums.GameStatus;

import java.util.UUID;

/**
 * Projeção pública de um jogo para outros módulos.
 */
public record GameInfo(UUID id, UUID homeTeamId, UUID awayTeamId, GameStatus status) {
}
