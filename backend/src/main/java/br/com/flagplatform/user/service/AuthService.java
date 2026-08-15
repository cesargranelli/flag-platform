package br.com.flagplatform.user.service;

import br.com.flagplatform.common.enums.UserRole;
import br.com.flagplatform.common.enums.UserStatus;
import br.com.flagplatform.user.TokenProvider;
import br.com.flagplatform.user.UserLookup;
import br.com.flagplatform.user.dto.request.CreateUserRequest;
import br.com.flagplatform.user.dto.request.LoginRequest;
import br.com.flagplatform.user.dto.request.RegisterRequest;
import br.com.flagplatform.user.dto.response.LoginResponse;
import br.com.flagplatform.user.dto.response.UserResponse;
import br.com.flagplatform.user.entity.UserEntity;
import br.com.flagplatform.user.exception.AccountPendingApprovalException;
import br.com.flagplatform.user.exception.EmailAlreadyExistsException;
import br.com.flagplatform.user.exception.InvalidCredentialsException;
import br.com.flagplatform.user.exception.UserNotFoundException;
import br.com.flagplatform.user.mapper.UserMapper;
import br.com.flagplatform.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService implements UserLookup {

    private final UserRepository userRepository;
    private final UserMapper mapper;
    private final PasswordEncoder passwordEncoder;
    private final TokenProvider tokenProvider;

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
