package br.com.flagplatform.competition.exception;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

/**
 * Encerramento permitido apenas quando o campeonato está em PUBLISHED.
 */
public class CompetitionNotFinishableException extends ApiException {

    public CompetitionNotFinishableException(CompetitionStatus status) {
        super(
                HttpStatus.BAD_REQUEST,
                "Competition not finishable",
                "Somente campeonatos publicados podem ser encerrados "
                        + "(status atual: %s).".formatted(status),
                "competition_not_finishable"
        );
    }

}