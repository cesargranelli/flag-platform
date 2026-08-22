package br.com.flagplatform.user;

import java.util.UUID;

/**
 * API pública do módulo user para consulta de usuários.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface UserLookup {

    UUID findUserIdByEmail(String email);

    boolean isAdminByEmail(String email);

}
