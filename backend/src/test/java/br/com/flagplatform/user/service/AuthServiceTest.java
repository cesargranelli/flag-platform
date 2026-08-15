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
import br.com.flagplatform.user.dto.response.LoginResponse;
import br.com.flagplatform.user.dto.response.UserResponse;
import br.com.flagplatform.user.entity.UserEntity;
import br.com.flagplatform.user.entity.PasswordResetTokenEntity;
import br.com.flagplatform.user.exception.AccountPendingApprovalException;
import br.com.flagplatform.user.exception.EmailAlreadyExistsException;
import br.com.flagplatform.user.exception.InvalidCredentialsException;
import br.com.flagplatform.user.exception.InvalidResetTokenException;
import br.com.flagplatform.user.mapper.UserMapper;
import br.com.flagplatform.user.repository.PasswordResetTokenRepository;
import br.com.flagplatform.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserMapper mapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private TokenProvider tokenProvider;

    @Mock
    private PasswordResetTokenRepository resetTokenRepository;

    @InjectMocks
    private AuthService service;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(service, "resetExpirationMinutes", 60L);
        ReflectionTestUtils.setField(service, "mailEnabled", false);
    }

    @Test
    void register_createsOrganizerWithPendingStatusAndHashedPassword() {
        RegisterRequest request = new RegisterRequest("Ana Lima", "  Ana@Exemplo.com ", "segredo123");
        UserEntity entity = entity("ana@exemplo.com", "encoded");
        UserResponse expected = response(entity);

        when(userRepository.existsByEmailIgnoreCase("ana@exemplo.com")).thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(passwordEncoder.encode("segredo123")).thenReturn("encoded");
        when(userRepository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        UserResponse response = service.register(request);

        assertThat(response).isSameAs(expected);
        assertThat(entity.getEmail()).isEqualTo("ana@exemplo.com");
        assertThat(entity.getPasswordHash()).isEqualTo("encoded");
        assertThat(entity.getRole()).isEqualTo(UserRole.ORGANIZER);
        assertThat(entity.getStatus()).isEqualTo(UserStatus.PENDING);
        verify(userRepository).save(entity);
    }

    @Test
    void register_throwsWhenEmailAlreadyExists() {
        RegisterRequest request = new RegisterRequest("Ana Lima", "ana@exemplo.com", "segredo123");

        when(userRepository.existsByEmailIgnoreCase("ana@exemplo.com")).thenReturn(true);

        assertThatThrownBy(() -> service.register(request))
                .isInstanceOf(EmailAlreadyExistsException.class);

        verify(userRepository, never()).save(any());
    }

    @Test
    void login_returnsTokenWhenCredentialsAreValid() {
        LoginRequest request = new LoginRequest("ana@exemplo.com", "segredo123");
        UserEntity user = entity("ana@exemplo.com", "encoded");
        UserResponse userResponse = response(user);

        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("segredo123", "encoded")).thenReturn(true);
        when(tokenProvider.generateToken("ana@exemplo.com")).thenReturn("jwt-token");
        when(tokenProvider.getExpirationSeconds()).thenReturn(3600L);
        when(mapper.toResponse(user)).thenReturn(userResponse);

        LoginResponse login = service.login(request);

        assertThat(login.token()).isEqualTo("jwt-token");
        assertThat(login.tokenType()).isEqualTo("Bearer");
        assertThat(login.expiresInSeconds()).isEqualTo(3600L);
        assertThat(login.user()).isSameAs(userResponse);
    }

    @Test
    void login_throwsWhenEmailNotFound() {
        LoginRequest request = new LoginRequest("ana@exemplo.com", "segredo123");

        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.login(request))
                .isInstanceOf(InvalidCredentialsException.class);

        verify(passwordEncoder, never()).matches(any(), any());
    }

    @Test
    void login_throwsWhenPasswordIsInvalid() {
        LoginRequest request = new LoginRequest("ana@exemplo.com", "senha-errada");
        UserEntity user = entity("ana@exemplo.com", "encoded");

        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("senha-errada", "encoded")).thenReturn(false);

        assertThatThrownBy(() -> service.login(request))
                .isInstanceOf(InvalidCredentialsException.class);

        verify(tokenProvider, never()).generateToken(any());
    }

    @Test
    void me_returnsUserForExistingEmail() {
        UserEntity user = entity("ana@exemplo.com", "encoded");
        UserResponse expected = response(user);

        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.of(user));
        when(mapper.toResponse(user)).thenReturn(expected);

        UserResponse response = service.me("ana@exemplo.com");

        assertThat(response).isSameAs(expected);
    }

    @Test
    void me_throwsWhenEmailNotFound() {
        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.me("ana@exemplo.com"))
                .isInstanceOf(InvalidCredentialsException.class);
    }

    @Test
    void createUser_savesUserWithGivenRole() {
        CreateUserRequest request =
                new CreateUserRequest("Mesa Central", "mesa@exemplo.com", "segredo123", UserRole.MESA);
        UserEntity entity = entity("mesa@exemplo.com", "encoded");
        UserResponse expected = response(entity);

        when(userRepository.existsByEmailIgnoreCase("mesa@exemplo.com")).thenReturn(false);
        when(passwordEncoder.encode("segredo123")).thenReturn("encoded");
        when(userRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(mapper.toResponse(any())).thenReturn(expected);

        UserResponse result = service.createUser(request);

        ArgumentCaptor<UserEntity> captor = ArgumentCaptor.forClass(UserEntity.class);
        verify(userRepository).save(captor.capture());
        assertThat(captor.getValue().getRole()).isEqualTo(UserRole.MESA);
        assertThat(captor.getValue().getEmail()).isEqualTo("mesa@exemplo.com");
        assertThat(captor.getValue().getStatus()).isEqualTo(UserStatus.ACTIVE);
        assertThat(result).isSameAs(expected);
    }

    @Test
    void createUser_throwsWhenEmailExists() {
        CreateUserRequest request =
                new CreateUserRequest("Mesa Central", "mesa@exemplo.com", "segredo123", UserRole.MESA);

        when(userRepository.existsByEmailIgnoreCase("mesa@exemplo.com")).thenReturn(true);

        assertThatThrownBy(() -> service.createUser(request))
                .isInstanceOf(EmailAlreadyExistsException.class);

        verify(userRepository, never()).save(any());
    }

    @Test
    void findAll_returnsUsersOrderedByName() {
        List<UserEntity> entities = List.of(entity("b@exemplo.com", "x"), entity("a@exemplo.com", "x"));
        List<UserResponse> expected = entities.stream().map(this::response).toList();

        when(userRepository.findAllByOrderByNameAsc()).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<UserResponse> result = service.findAll();

        assertThat(result).hasSize(2).isSameAs(expected);
    }

    @Test
    void login_throwsWhenAccountIsPending() {
        LoginRequest request = new LoginRequest("ana@exemplo.com", "segredo123");
        UserEntity user = entity("ana@exemplo.com", "encoded");
        user.setStatus(UserStatus.PENDING);

        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("segredo123", "encoded")).thenReturn(true);

        assertThatThrownBy(() -> service.login(request))
                .isInstanceOf(AccountPendingApprovalException.class);

        verify(tokenProvider, never()).generateToken(any());
    }

    @Test
    void listPending_returnsOnlyPendingUsers() {
        UserEntity pending = entity("ana@exemplo.com", "x");
        pending.setStatus(UserStatus.PENDING);
        List<UserEntity> entities = List.of(pending);
        List<UserResponse> expected = entities.stream().map(this::response).toList();

        when(userRepository.findAllByStatusOrderByCreatedAtAsc(UserStatus.PENDING)).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<UserResponse> result = service.listPending();

        assertThat(result).hasSize(1).isSameAs(expected);
    }

    @Test
    void approve_activatesPendingAccount() {
        UUID id = UUID.randomUUID();
        UserEntity user = entity("ana@exemplo.com", "x");
        user.setStatus(UserStatus.PENDING);
        UserResponse expected = response(user);

        when(userRepository.findById(id)).thenReturn(Optional.of(user));
        when(userRepository.save(user)).thenReturn(user);
        when(mapper.toResponse(user)).thenReturn(expected);

        UserResponse result = service.approve(id);

        assertThat(result).isSameAs(expected);
        assertThat(user.getStatus()).isEqualTo(UserStatus.ACTIVE);
    }

    @Test
    void reject_marksAccountAsRejected() {
        UUID id = UUID.randomUUID();
        UserEntity user = entity("ana@exemplo.com", "x");
        user.setStatus(UserStatus.PENDING);
        UserResponse expected = response(user);

        when(userRepository.findById(id)).thenReturn(Optional.of(user));
        when(userRepository.save(user)).thenReturn(user);
        when(mapper.toResponse(user)).thenReturn(expected);

        UserResponse result = service.reject(id);

        assertThat(result).isSameAs(expected);
        assertThat(user.getStatus()).isEqualTo(UserStatus.REJECTED);
    }

    @Test
    void requestPasswordReset_generatesToken_whenUserExists() {
        UserEntity user = entity("ana@exemplo.com", "encoded");
        when(userRepository.findByEmailIgnoreCase("ana@exemplo.com")).thenReturn(Optional.of(user));
        when(resetTokenRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        var response = service.requestPasswordReset(
                new ForgotPasswordRequest("Ana@Exemplo.com"));

        assertThat(response.resetToken()).isNotBlank();
        verify(resetTokenRepository).save(any());
    }

    @Test
    void requestPasswordReset_returnsGeneric_whenUserNotFound() {
        when(userRepository.findByEmailIgnoreCase("nao-existe@exemplo.com")).thenReturn(Optional.empty());

        var response = service.requestPasswordReset(
                new ForgotPasswordRequest("nao-existe@exemplo.com"));

        assertThat(response.resetToken()).isNull();
        verify(resetTokenRepository, never()).save(any());
    }

    @Test
    void resetPassword_updatesPasswordAndMarksTokenUsed() {
        UUID userId = UUID.randomUUID();
        UserEntity user = entity("ana@exemplo.com", "old");
        PasswordResetTokenEntity token = new PasswordResetTokenEntity();
        token.setUserId(userId);
        token.setTokenHash("hash");
        token.setExpiresAt(LocalDateTime.now().plusMinutes(30));

        when(resetTokenRepository.findByTokenHashAndUsedAtIsNull(any())).thenReturn(Optional.of(token));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(passwordEncoder.encode("nova-senha")).thenReturn("encoded-new");
        when(userRepository.save(user)).thenReturn(user);

        service.resetPassword(new ResetPasswordRequest("raw-token", "nova-senha"));

        assertThat(user.getPasswordHash()).isEqualTo("encoded-new");
        assertThat(token.getUsedAt()).isNotNull();
        verify(resetTokenRepository).save(token);
    }

    @Test
    void resetPassword_throwsWhenTokenInvalid() {
        when(resetTokenRepository.findByTokenHashAndUsedAtIsNull(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.resetPassword(new ResetPasswordRequest("bad", "nova-senha")))
                .isInstanceOf(InvalidResetTokenException.class);

        verify(userRepository, never()).save(any());
    }

    @Test
    void resetPassword_throwsWhenTokenExpired() {
        PasswordResetTokenEntity token = new PasswordResetTokenEntity();
        token.setUserId(UUID.randomUUID());
        token.setExpiresAt(LocalDateTime.now().minusMinutes(1));

        when(resetTokenRepository.findByTokenHashAndUsedAtIsNull(any())).thenReturn(Optional.of(token));

        assertThatThrownBy(() -> service.resetPassword(new ResetPasswordRequest("expired", "nova-senha")))
                .isInstanceOf(InvalidResetTokenException.class);

        verify(userRepository, never()).save(any());
    }

    private UserEntity entity(String email, String passwordHash) {
        UserEntity entity = new UserEntity();
        entity.setId(UUID.randomUUID());
        entity.setName("Ana Lima");
        entity.setEmail(email);
        entity.setPasswordHash(passwordHash);
        entity.setRole(UserRole.ORGANIZER);
        entity.setStatus(UserStatus.ACTIVE);
        return entity;
    }

    private UserResponse response(UserEntity entity) {
        return new UserResponse(
                entity.getId(),
                entity.getName(),
                entity.getEmail(),
                entity.getRole(),
                entity.getStatus(),
                LocalDateTime.of(2026, 8, 13, 10, 0));
    }

}
