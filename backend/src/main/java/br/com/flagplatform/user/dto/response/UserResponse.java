package br.com.flagplatform.user.dto.response;

import br.com.flagplatform.common.enums.UserRole;
import br.com.flagplatform.common.enums.UserStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String name,
        String email,
        UserRole role,
        UserStatus status,
        LocalDateTime createdAt
) {
}
