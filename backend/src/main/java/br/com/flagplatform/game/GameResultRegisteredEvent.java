package br.com.flagplatform.game;

import java.util.UUID;

public record GameResultRegisteredEvent(UUID gameId, UUID competitionId) {
}
