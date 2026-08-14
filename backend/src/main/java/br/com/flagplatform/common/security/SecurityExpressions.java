package br.com.flagplatform.common.security;

/**
 * Expressões SpEL usadas nas anotações @PreAuthorize dos controllers.
 * <p>
 * Centralizadas para evitar duplicação de literais e manter o mapeamento de
 * roles consistente entre os módulos.
 */
public final class SecurityExpressions {

    /**
     * Escrita de dados de gestão (organizações, campeonatos, categorias,
     * campos, times, rodadas e agendamento de jogos).
     */
    public static final String ADMIN_OR_ORGANIZER = "hasAnyRole('ADMIN', 'ORGANIZER')";

    /**
     * Operação de jogos ao vivo (status e resultado da partida, executada pela mesa).
     */
    public static final String ADMIN_OR_MESA = "hasAnyRole('ADMIN', 'MESA')";

    /**
     * Ações exclusivas de administrador (ex: gestão de usuários).
     */
    public static final String ADMIN = "hasRole('ADMIN')";

    private SecurityExpressions() {
    }
}
