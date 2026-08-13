package br.com.flagplatform.roster.controller;

import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.roster.dto.request.AddRosterEntryRequest;
import br.com.flagplatform.roster.dto.response.RosterEntryResponse;
import br.com.flagplatform.roster.service.RosterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Roster", description = "Endpoints para gerenciar o elenco dos times")
@RestController
@RequiredArgsConstructor
public class RosterController {

    private final RosterService service;

    @Operation(
            summary = "Inscrever atleta no time",
            description = "Adiciona um atleta ao elenco de um time. Requer autenticação."
    )
    @PostMapping("/api/v1/teams/{teamId}/roster")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public RosterEntryResponse add(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Valid @RequestBody AddRosterEntryRequest request) {
        return service.add(teamId, request);
    }

    @Operation(
            summary = "Listar elenco do time",
            description = "Lista os atletas inscritos em um time, ordenados por nome. Acesso público."
    )
    @GetMapping("/api/v1/teams/{teamId}/roster")
    public List<RosterEntryResponse> findRosterByTeam(
            @Parameter(description = "Id do time") @PathVariable UUID teamId) {
        return service.findRosterByTeam(teamId);
    }

    @Operation(
            summary = "Remover atleta do time",
            description = "Remove um atleta do elenco de um time. Requer autenticação."
    )
    @DeleteMapping("/api/v1/teams/{teamId}/roster/{athleteId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void remove(
            @Parameter(description = "Id do time") @PathVariable UUID teamId,
            @Parameter(description = "Id do atleta") @PathVariable UUID athleteId) {
        service.remove(teamId, athleteId);
    }

}
