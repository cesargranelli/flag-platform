package br.com.flagplatform.game;

import java.util.UUID;

public record FinishedGame(UUID homeTeamId, UUID awayTeamId, int homeScore, int awayScore) {
}
