package br.com.flagplatform.standing.controller;

import br.com.flagplatform.standing.dto.response.StandingResponse;
import br.com.flagplatform.standing.service.StandingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Standings", description = "Endpoints para consultar a classificacao")
@RestController
@RequiredArgsConstructor
public class StandingController {

    private final StandingService service;

    @Operation(
            summary = "Consultar classificacao",
            description = "Retorna a tabela de classificacao de um campeonato, ordenada por pontos, saldo de gols e gols pro. Acesso publico."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/standings")
    public List<StandingResponse> findByCompetitionId(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

}
