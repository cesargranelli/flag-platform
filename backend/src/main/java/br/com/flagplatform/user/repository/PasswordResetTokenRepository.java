package br.com.flagplatform.user.repository;

import br.com.flagplatform.user.entity.PasswordResetTokenEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PasswordResetTokenRepository
        extends JpaRepository<PasswordResetTokenEntity, UUID> {

    Optional<PasswordResetTokenEntity> findByTokenHashAndUsedAtIsNull(String tokenHash);

    Optional<PasswordResetTokenEntity> findTopByUserIdOrderByCreatedAtDesc(UUID userId);

}
