package br.com.flagplatform.team.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

/**
 * Lançada ao tentar remover um time (desassociar clube) que já possui dados
 * vinculados (ex.: jogos), o que impede a exclusão por integridade referencial.
 */
public class TeamInUseException extends ApiException {

    public TeamInUseException(UUID id) {
        super(
                HttpStatus.CONFLICT,
                "Team in use",
                "Não é possível desassociar o clube: ele já possui jogos associados.",
                "team_in_use"
        );
    }

}
