package br.com.flagplatform.competition.exception;

import br.com.flagplatform.common.enums.CompetitionStatus;
import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

/**
 * Edição permitida apenas enquanto o campeonato está em DRAFT (V250).
 * Após publicado/encerrado/desativado, nenhuma alteração é aceita.
 */
public class CompetitionNotEditableException extends ApiException {

    public CompetitionNotEditableException(CompetitionStatus status) {
        super(
                HttpStatus.CONFLICT,
                "Competition not editable",
                "Somente campeonatos em rascunho podem ser editados "
                        + "(status atual: %s).".formatted(status),
                "competition_not_editable"
        );
    }

}
