package br.com.flagplatform.game;

import java.util.UUID;

/**
 * Projeção pública de um jogo para outros módulos.
 */
public record GameInfo(UUID id, UUID homeTeamId, UUID awayTeamId) {
}
