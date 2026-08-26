package br.com.flagplatform.competition;

import java.util.UUID;

/**
 * API pública do módulo competition para consulta de campeonatos.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface CompetitionLookup {

    void assertExists(UUID id);

    /**
     * Garante que o usu&aacute;rio autenticado (identificado pelo e-mail do JWT)
     * &eacute; o criador do campeonato ou ADMIN. Caso contr&aacute;rio, lan&ccedil;a 403.
     * Campeonatos legados sem criador conhecido ficam restritos ao ADMIN.
     */
    void assertManagedBy(UUID competitionId, String currentUserEmail);

    /**
     * Issue #305: garante que o campeonato est&aacute; em DRAFT &mdash; &uacute;nico
     * status em que a estrutura (confer&ecirc;ncias, divis&otilde;es, grupos e rodadas)
     * pode ser alterada. Caso contr&aacute;rio, lan&ccedil;a 409.
     */
    void assertEditable(UUID competitionId);
}
