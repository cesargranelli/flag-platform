package br.com.flagplatform.common.exception;

public record ValidationFieldError(
        String field,
        String message
) {
}
