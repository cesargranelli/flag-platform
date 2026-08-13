package br.com.flagplatform.user.controller;

import br.com.flagplatform.user.dto.request.LoginRequest;
import br.com.flagplatform.user.dto.request.RegisterRequest;
import br.com.flagplatform.user.dto.response.LoginResponse;
import br.com.flagplatform.user.dto.response.UserResponse;
import br.com.flagplatform.user.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Auth", description = "Cadastro, autenticação e usuário atual")
@RequestMapping("/api/v1/auth")
@RestController
@RequiredArgsConstructor
public class AuthController {

    private final AuthService service;

    @Operation(
            summary = "Cadastrar usuário",
            description = "Cria um usuário com o papel ORGANIZER. Acesso público."
    )
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse register(@Valid @RequestBody RegisterRequest request) {
        return service.register(request);
    }

    @Operation(
            summary = "Autenticar",
            description = "Valida credenciais e retorna um token JWT. Acesso público."
    )
    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request) {
        return service.login(request);
    }

    @Operation(
            summary = "Usuário atual",
            description = "Retorna o usuário autenticado pelo token JWT."
    )
    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal UserDetails principal) {
        return service.me(principal.getUsername());
    }

}
