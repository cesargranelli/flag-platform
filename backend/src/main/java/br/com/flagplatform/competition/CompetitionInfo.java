package br.com.flagplatform.competition;

import br.com.flagplatform.common.enums.Gender;
import br.com.flagplatform.common.enums.Modality;

import java.util.UUID;

/**
 * Projeção pública de um campeonato para outros módulos.
 * <p>
 * Fica na raiz do módulo para não vazar API interna (entidade/DTO) e manter
 * o isolamento do Spring Modulith.
 */
public record CompetitionInfo(UUID id, String name, Modality modality, Gender gender) {
}
