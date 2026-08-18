package br.com.flagplatform.checkin.controller;

import br.com.flagplatform.checkin.dto.request.CheckInStatusRequest;
import br.com.flagplatform.checkin.dto.request.MatchNumberRequest;
import br.com.flagplatform.checkin.dto.response.CheckInResponse;
import br.com.flagplatform.checkin.dto.response.ValidationResponse;
import br.com.flagplatform.checkin.service.CheckInService;
import br.com.flagplatform.common.security.SecurityExpressions;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Check-in", description = "Endpoints para validar presenca de atletas antes da partida")
@RestController
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService service;

    @Operation(
            summary = "Listar check-in da partida",
            description = "Retorna o roster dos dois times do jogo com o status de check-in de cada atleta."
    )
    @GetMapping("/api/v1/games/{gameId}/checkin")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public List<CheckInResponse> getCheckinList(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId) {
        return service.getCheckinList(gameId);
    }

    @Operation(
            summary = "Registrar check-in de atleta",
            description = "Marca um atleta do jogo como PRESENT ou NO_SHOW. "
                    + "Registra quem validou e quando."
    )
    @PostMapping("/api/v1/games/{gameId}/checkin/{athleteId}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public CheckInResponse checkin(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId,
            @Parameter(description = "Id do atleta") @PathVariable UUID athleteId,
            @Valid @RequestBody CheckInStatusRequest request,
            @AuthenticationPrincipal UserDetails principal) {
        return service.checkin(gameId, athleteId, request, principal.getUsername());
    }

    @Operation(
            summary = "Validar atleta durante a partida",
            description = "Valida a entrada de um atleta durante a partida (IN_PROGRESS). "
                    + "Retorna NOT_REGISTERED se o atleta não estiver no roster dos times."
    )
    @PostMapping("/api/v1/games/{gameId}/checkin/{athleteId}/validate")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public ValidationResponse validate(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId,
            @Parameter(description = "Id do atleta") @PathVariable UUID athleteId,
            @AuthenticationPrincipal UserDetails principal) {
        return service.validate(gameId, athleteId, principal.getUsername());
    }

    @Operation(
            summary = "Definir numeração de partida do atleta",
            description = "Troca o numero do atleta apenas para esta partida, sem alterar o "
                    + "numero oficial. Body {number: null} limpa o override (volta ao oficial). "
                    + "Bloqueia numero duplicado dentro do mesmo time na partida."
    )
    @PutMapping("/api/v1/games/{gameId}/checkin/{athleteId}/match-number")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_MESA)
    public CheckInResponse setMatchNumber(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId,
            @Parameter(description = "Id do atleta") @PathVariable UUID athleteId,
            @Valid @RequestBody MatchNumberRequest request) {
        return service.setMatchNumber(gameId, athleteId, request);
    }

    @Operation(
            summary = "Consultar validações do jogo",
            description = "Retorna o roster dos dois times com o status de validação de cada atleta. "
                    + "Acesso público."
    )
    @GetMapping("/api/v1/games/{gameId}/validations")
    public List<CheckInResponse> getValidations(
            @Parameter(description = "Id do jogo") @PathVariable UUID gameId) {
        return service.getCheckinList(gameId);
    }

}
