package br.com.flagplatform.user.service;

import br.com.flagplatform.common.enums.UserRole;
import br.com.flagplatform.common.enums.UserStatus;
import br.com.flagplatform.user.TokenProvider;
import br.com.flagplatform.user.UserLookup;
import br.com.flagplatform.user.dto.request.CreateUserRequest;
import br.com.flagplatform.user.dto.request.ForgotPasswordRequest;
import br.com.flagplatform.user.dto.request.LoginRequest;
import br.com.flagplatform.user.dto.request.RegisterRequest;
import br.com.flagplatform.user.dto.request.ResetPasswordRequest;
import br.com.flagplatform.user.dto.response.ForgotPasswordResponse;
import br.com.flagplatform.user.dto.response.LoginResponse;
import br.com.flagplatform.user.dto.response.UserResponse;
import br.com.flagplatform.user.entity.PasswordResetTokenEntity;
import br.com.flagplatform.user.entity.UserEntity;
import br.com.flagplatform.user.exception.AccountPendingApprovalException;
import br.com.flagplatform.user.exception.EmailAlreadyExistsException;
import br.com.flagplatform.user.exception.InvalidCredentialsException;
import br.com.flagplatform.user.exception.InvalidResetTokenException;
import br.com.flagplatform.user.exception.UserNotFoundException;
import br.com.flagplatform.user.mapper.UserMapper;
import br.com.flagplatform.user.repository.PasswordResetTokenRepository;
import br.com.flagplatform.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService implements UserLookup {

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository resetTokenRepository;
    private final UserMapper mapper;
    private final PasswordEncoder passwordEncoder;
    private final TokenProvider tokenProvider;

    @Value("${app.security.password-reset.expiration-minutes:60}")
    private long resetExpirationMinutes;

    @Value("${app.mail.enabled:false}")
    private boolean mailEnabled;

    @Transactional
    public UserResponse register(RegisterRequest request) {
        String email = normalize(request.email());

        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new EmailAlreadyExistsException(email);
        }

        UserEntity entity = mapper.toEntity(request);
        entity.setEmail(email);
        entity.setPasswordHash(passwordEncoder.encode(request.password()));
        entity.setRole(UserRole.ORGANIZER);
        entity.setStatus(UserStatus.PENDING);

        return mapper.toResponse(userRepository.save(entity));
    }

    public LoginResponse login(LoginRequest request) {
        UserEntity user = userRepository.findByEmailIgnoreCase(normalize(request.email()))
                .orElseThrow(InvalidCredentialsException::new);

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }

        requireActive(user);

        String token = tokenProvider.generateToken(user.getEmail());

        return new LoginResponse(
                token,
                "Bearer",
                tokenProvider.getExpirationSeconds(),
                mapper.toResponse(user));
    }

    public UserResponse me(String email) {
        UserEntity user = userRepository.findByEmailIgnoreCase(normalize(email))
                .orElseThrow(InvalidCredentialsException::new);
        return mapper.toResponse(user);
    }

    @Override
    public UUID findUserIdByEmail(String email) {
        return userRepository.findByEmailIgnoreCase(normalize(email))
                .orElseThrow(InvalidCredentialsException::new)
                .getId();
    }

    @Override
    public boolean isAdminByEmail(String email) {
        return userRepository.findByEmailIgnoreCase(normalize(email))
                .map(user -> user.getRole() == UserRole.ADMIN)
                .orElse(false);
    }

    @Transactional
    public UserResponse createUser(CreateUserRequest request) {
        String email = normalize(request.email());

        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new EmailAlreadyExistsException(email);
        }

        UserEntity entity = new UserEntity();
        entity.setName(request.name().trim());
        entity.setEmail(email);
        entity.setPasswordHash(passwordEncoder.encode(request.password()));
        entity.setRole(request.role());
        entity.setStatus(UserStatus.ACTIVE);

        return mapper.toResponse(userRepository.save(entity));
    }

    public List<UserResponse> findAll() {
        return mapper.toResponseList(userRepository.findAllByOrderByNameAsc());
    }

    public List<UserResponse> listPending() {
        return mapper.toResponseList(
                userRepository.findAllByStatusOrderByCreatedAtAsc(UserStatus.PENDING));
    }

    @Transactional
    public UserResponse approve(UUID id) {
        UserEntity user = findEntityById(id);
        user.setStatus(UserStatus.ACTIVE);
        return mapper.toResponse(userRepository.save(user));
    }

    @Transactional
    public UserResponse reject(UUID id) {
        UserEntity user = findEntityById(id);
        user.setStatus(UserStatus.REJECTED);
        return mapper.toResponse(userRepository.save(user));
    }

    private UserEntity findEntityById(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
    }

    @Transactional
    public ForgotPasswordResponse requestPasswordReset(ForgotPasswordRequest request) {
        String email = normalize(request.email());
        UserEntity user = userRepository.findByEmailIgnoreCase(email).orElse(null);

        if (user == null) {
            // Não revela se o e-mail existe (evita enumeração).
            return new ForgotPasswordResponse(
                    "If the email exists, a reset link was sent.", null);
        }

        String token = generateToken();
        PasswordResetTokenEntity entity = new PasswordResetTokenEntity();
        entity.setUserId(user.getId());
        entity.setTokenHash(hash(token));
        entity.setExpiresAt(LocalDateTime.now().plusMinutes(resetExpirationMinutes));
        resetTokenRepository.save(entity);

        // SMTP ainda não configurado: em dev o token é retornado na resposta.
        // Quando app.mail.enabled=true, enviar e-mail com o link (TODO: integração de e-mail).
        String resetToken = mailEnabled ? null : token;

        return new ForgotPasswordResponse(
                "A password reset link was sent to your email.", resetToken);
    }

    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetTokenEntity token = resetTokenRepository
                .findByTokenHashAndUsedAtIsNull(hash(request.token()))
                .orElseThrow(InvalidResetTokenException::new);

        if (token.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new InvalidResetTokenException();
        }

        UserEntity user = userRepository.findById(token.getUserId())
                .orElseThrow(() -> new UserNotFoundException(token.getUserId()));

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);

        token.setUsedAt(LocalDateTime.now());
        resetTokenRepository.save(token);
    }

    private String generateToken() {
        return UUID.randomUUID().toString().replace("-", "")
                + UUID.randomUUID().toString().replace("-", "");
    }

    private String hash(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(bytes);
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 not available", ex);
        }
    }

    private void requireActive(UserEntity user) {
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new AccountPendingApprovalException(
                    "Account is not active (status: %s).".formatted(user.getStatus()));
        }
    }

    private String normalize(String email) {
        return email == null ? null : email.trim().toLowerCase();
    }

}
