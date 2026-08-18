package br.com.flagplatform.modality;

import java.util.List;
import java.util.UUID;

/**
 * API pública do módulo modality para consulta de modalidades.
 * <p>
 * Sem tipos de subpacote (DTO/exception) na assinatura para não vazar
 * API interna e manter o isolamento do Spring Modulith.
 */
public interface ModalityLookup {

    void assertExists(UUID id);

    boolean existsById(UUID id);

    ModalityInfo findModalityInfoById(UUID id);

    List<ModalityInfo> listModalityInfo();

}
