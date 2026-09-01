package br.com.flagplatform.competition.controller;

import br.com.flagplatform.competition.dto.request.CreateCompetitionRequest;
import br.com.flagplatform.competition.dto.request.UpdateCompetitionRequest;
import br.com.flagplatform.competition.dto.response.CompetitionResponse;
import br.com.flagplatform.competition.dto.response.CompetitionSummaryResponse;
import br.com.flagplatform.common.security.CurrentUser;
import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.competition.service.CompetitionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Competitions", description = "Endpoints para criar e gerenciar campeonatos")
@RestController
@RequiredArgsConstructor
public class CompetitionController {

    private final CompetitionService service;

    @Operation(
            summary = "Criar campeonato",
            description = "Cria um novo campeonato. O usuário autenticado é registrado como criador "
                    + "e passa a ser o único (além do ADMIN) autorizado a editá-lo e gerenciar seus recursos. "
                    + "A estrutura (conferências e divisões) é adicionada manualmente pelo organizador. "
                    + "Requer autenticação."
    )
    @PostMapping("/api/v1/competitions")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CompetitionResponse create(
            @Valid @RequestBody CreateCompetitionRequest request,
            Authentication authentication) {
        return service.create(request, authentication.getName());
    }

    @Operation(
            summary = "Listar campeonatos",
            description = "Lista os campeonatos publicáveis (DRAFT/PUBLISHED/FINISHED), com nome da organização. "
                    + "Com includeDisabled=true e role ADMIN, inclui também os desativados. Acesso público."
    )
    @GetMapping("/api/v1/competitions")
    public List<CompetitionSummaryResponse> listAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            @RequestParam(defaultValue = "false") boolean includeDisabled,
            Authentication authentication,
            HttpServletResponse response) {
        var result = service.listAllPublic(page, size, includeDisabled, CurrentUser.isAdmin(authentication));
        response.setHeader("X-Total-Count", String.valueOf(result.total()));
        return result.items();
    }

    @Operation(
            summary = "Buscar campeonato por id",
            description = "Retorna o detalhe de um campeonato. Desativados são visíveis apenas ao ADMIN. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{id}")
    public CompetitionResponse getById(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id,
            Authentication authentication) {
        return service.findById(id, CurrentUser.isAdmin(authentication));
    }

    @Operation(
            summary = "Desativar campeonato",
            description = "Exclusão lógica: marca o campeonato como DISABLED. Ele deixa de aparecer nas listagens e só o ADMIN pode reativar. "
                    + "Permitido apenas ao criador do campeonato ou ADMIN."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @DeleteMapping("/api/v1/competitions/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void deactivate(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id,
            Authentication authentication) {
        service.deactivate(id, authentication.getName());
    }

    @Operation(
            summary = "Reativar campeonato",
            description = "Reverte a desativação lógica, voltando o campeonato para DRAFT. Exclusivo do ADMIN."
    )
    @PostMapping("/api/v1/competitions/{id}/reactivate")
    @PreAuthorize(SecurityExpressions.ADMIN)
    public void reactivate(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id) {
        service.reactivate(id);
    }

    @Operation(
            summary = "Encerrar campeonato",
            description = "Marca o campeonato como FINISHED (transição PUBLISHED → FINISHED). "
                    + "Permitido apenas ao criador do campeonato ou ADMIN, enquanto estiver em status PUBLISHED."
    )
    @ApiResponse(responseCode = "400", description = "Campeonato não está em status PUBLISHED")
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @PostMapping("/api/v1/competitions/{id}/finish")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void finish(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id,
            Authentication authentication) {
        service.finish(id, authentication.getName());
    }

    @Operation(
            summary = "Listar campeonatos por organização",
            description = "Lista os campeonatos de uma organização, ordenados por nome. Desativados só aparecem para ADMIN com includeDisabled=true. Acesso público."
    )
    @GetMapping("/api/v1/organizations/{organizationId}/competitions")
    public List<CompetitionResponse> findByOrganizationId(
            @Parameter(description = "Id da organização") @PathVariable UUID organizationId,
            @RequestParam(defaultValue = "false") boolean includeDisabled,
            Authentication authentication) {
        return service.findByOrganizationId(
                organizationId, includeDisabled, CurrentUser.isAdmin(authentication));
    }

    @Operation(
            summary = "Atualizar campeonato",
            description = "Atualiza um campeonato existente. Permitido apenas ao criador do campeonato ou ADMIN, "
                    + "enquanto estiver em status DRAFT."
    )
    @ApiResponse(responseCode = "403", description = "Usuário não é o criador do campeonato nem ADMIN")
    @ApiResponse(responseCode = "409", description = "Campeonato não está em status DRAFT")
    @PutMapping("/api/v1/competitions/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CompetitionResponse update(
            @Parameter(description = "Id do campeonato") @PathVariable UUID id,
            @Valid @RequestBody UpdateCompetitionRequest request,
            Authentication authentication) {
        return service.update(id, request, authentication.getName());
    }

}
