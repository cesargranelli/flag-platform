package br.com.flagplatform.play.dto.response;

import br.com.flagplatform.play.entity.PlayType;

import java.util.UUID;

public record PlayResponse(
        UUID id,
        UUID gameId,
        UUID teamId,
        String teamName,
        String playerName,
        String receiverName,
        PlayType playType,
        String description,
        Integer yards,
        String quarter,
        String time,
        Boolean isFirstDown,
        Boolean isTouchdown,
        Boolean isTurnover
) {
}
