package br.com.flagplatform.round;

import java.util.UUID;

/**
 * Projeção pública de uma rodada para outros módulos.
 * <p>
 * Fica na raiz do módulo para não vazar API interna (entidade/DTO) e manter
 * o isolamento do Spring Modulith.
 */
public record RoundInfo(UUID id, Integer number) {
}
