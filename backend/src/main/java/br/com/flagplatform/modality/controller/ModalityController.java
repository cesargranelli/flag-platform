package br.com.flagplatform.modality.controller;

import br.com.flagplatform.modality.dto.response.ModalityResponse;
import br.com.flagplatform.modality.service.ModalityService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Modalities", description = "Endpoints para consulta de modalidades")
@RestController
@RequiredArgsConstructor
public class ModalityController {

    private final ModalityService service;

    @Operation(
            summary = "Listar modalidades",
            description = "Lista as modalidades ativas (Flag 5x5, 8x8, 9x9, Full Pads 11x11 etc.), ordenadas por formato. Acesso público."
    )
    @GetMapping("/api/v1/modalities")
    public List<ModalityResponse> list() {
        return service.listActive();
    }

    @Operation(
            summary = "Obter modalidade",
            description = "Retorna o detalhe de uma modalidade. Acesso público."
    )
    @GetMapping("/api/v1/modalities/{id}")
    public ModalityResponse findById(
            @Parameter(description = "Id da modalidade") @PathVariable UUID id) {
        return service.findById(id);
    }

}
