package br.com.flagplatform.competition.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

/**
 * Escrita de configuração permitida apenas ao criador do campeonato
 * ou ao ADMIN (V260). Campeonatos legados sem criador ficam restritos ao ADMIN.
 */
public class CompetitionNotOwnedByCreatorException extends ApiException {

    public CompetitionNotOwnedByCreatorException() {
        super(
                HttpStatus.FORBIDDEN,
                "Competition not owned by creator",
                "Apenas o criador do campeonato pode realizar esta ação.",
                "competition_not_owned_by_creator"
        );
    }

}
