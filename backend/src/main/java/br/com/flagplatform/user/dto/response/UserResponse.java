package br.com.flagplatform.user.dto.response;

import br.com.flagplatform.common.enums.UserRole;

import java.time.LocalDateTime;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String name,
        String email,
        UserRole role,
        LocalDateTime createdAt
) {
}
