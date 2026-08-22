package br.com.flagplatform.common.security;

import org.springframework.security.core.Authentication;

/**
 * Utilitários para inspecionar o usuário autenticado nos casos em que a
 * visibilidade do recurso depende do papel (ex.: itens desativados só são
 * visíveis ao ADMIN). Seguro para endpoints públicos — anonimo retorna false.
 */
public final class CurrentUser {

    private CurrentUser() {
    }

    public static boolean isAdmin(Authentication authentication) {
        return authentication != null && authentication.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
    }

}
