package br.com.flagplatform.category;

import java.util.UUID;

/**
 * API pública do módulo category para consulta de categorias.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface CategoryLookup {

    void assertExists(UUID id);

}
