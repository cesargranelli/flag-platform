package br.com.flagplatform.division;

import java.util.UUID;

/**
 * Projeção pública de uma divisão para outros módulos.
 * <p>
 * Fica na raiz do módulo para não vazar API interna (entidade/DTO) e manter
 * o isolamento do Spring Modulith.
 */
public record DivisionInfo(UUID id, UUID competitionId, UUID conferenceId, String name) {
}
