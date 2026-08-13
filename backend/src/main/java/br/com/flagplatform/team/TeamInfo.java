package br.com.flagplatform.team;

import java.util.UUID;

/**
 * Projeção pública de um time para outros módulos.
 * <p>
 * Fica na raiz do módulo para não vazar API interna (entidade/DTO) e manter
 * o isolamento do Spring Modulith.
 */
public record TeamInfo(UUID id, String name) {
}
