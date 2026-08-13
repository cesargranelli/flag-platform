package br.com.flagplatform.user.dto.response;

public record LoginResponse(
        String token,
        String tokenType,
        long expiresInSeconds,
        UserResponse user
) {
}
