package br.com.flagplatform.user.dto.response;

public record ForgotPasswordResponse(
        String message,
        String resetToken
) {
}
