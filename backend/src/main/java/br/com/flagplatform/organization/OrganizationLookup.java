package br.com.flagplatform.organization;

import java.util.UUID;

/**
 * API pública do módulo organization para consulta de organizações.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface OrganizationLookup {

    void assertExists(UUID id);

    String findTradeNameById(UUID id);

}
