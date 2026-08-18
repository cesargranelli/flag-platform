package br.com.flagplatform.modality.exception;

import br.com.flagplatform.common.exception.ApiException;
import org.springframework.http.HttpStatus;

import java.util.UUID;

public class ModalityNotFoundException extends ApiException {

    public ModalityNotFoundException(UUID id) {
        super(
                HttpStatus.NOT_FOUND,
                "Modality not found",
                "Modality with id '%s' was not found.".formatted(id),
                "code"
        );
    }

}
