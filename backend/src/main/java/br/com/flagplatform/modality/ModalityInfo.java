package br.com.flagplatform.modality;

import java.util.UUID;

/**
 * Projeção pública de uma modalidade para outros módulos.
 * <p>
 * Fica na raiz do módulo para não vazar API interna (entidade/DTO) e manter
 * o isolamento do Spring Modulith.
 */
public record ModalityInfo(UUID id, String name, String format) {
}
