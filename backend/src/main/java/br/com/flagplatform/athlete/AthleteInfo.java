package br.com.flagplatform.athlete;

import br.com.flagplatform.common.enums.AthletePosition;

import java.util.UUID;

/**
 * Projeção pública de um atleta para outros módulos (ex: elenco de times).
 */
public record AthleteInfo(
        UUID id,
        String name,
        String nickname,
        AthletePosition position,
        Integer number,
        String photoUrl
) {
}
