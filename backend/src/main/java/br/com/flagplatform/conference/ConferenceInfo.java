package br.com.flagplatform.conference;

import java.util.UUID;

/**
 * Projeção pública de uma conferência para outros módulos.
 * <p>
 * Fica na raiz do módulo para não vazar API interna (entidade/DTO) e manter
 * o isolamento do Spring Modulith.
 */
public record ConferenceInfo(UUID id, UUID competitionId, String name) {
}
