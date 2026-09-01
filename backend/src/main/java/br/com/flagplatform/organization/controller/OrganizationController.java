package br.com.flagplatform.organization.controller;

import br.com.flagplatform.common.security.CurrentUser;
import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.organization.dto.request.AssociateClubRequest;
import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.dto.response.OrganizationResponse;
import br.com.flagplatform.organization.service.OrganizationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Organizations", description = "Endpoints para criar e gerenciar organizações esportivas")
@RequestMapping("/api/v1/organizations")
@RestController
@RequiredArgsConstructor
public class OrganizationController {

    private final OrganizationService service;

    @Operation(
            summary = "Criar organização",
            description = "Cria uma nova organização esportiva. Requer autenticação."
    )
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public OrganizationCreatedResponse create(@Valid @RequestBody CreateOrganizationRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar organizações",
            description = "Lista as organizações esportivas ativas, com paginação (page/size) e total no header X-Total-Count. "
                    + "Com includeDisabled=true e role ADMIN, inclui também as desativadas. Acesso público."
    )
    @GetMapping
    public List<OrganizationResponse> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            @RequestParam(defaultValue = "false") boolean includeDisabled,
            Authentication authentication,
            HttpServletResponse response) {
        var result = service.findAll(page, size, includeDisabled, CurrentUser.isAdmin(authentication));
        response.setHeader("X-Total-Count", String.valueOf(result.total()));
        return result.items();
    }

    @Operation(
            summary = "Buscar organização por id",
            description = "Retorna o detalhe de uma organização esportiva. Organizações desativadas são visíveis apenas ao ADMIN. Acesso público."
    )
    @GetMapping("/{id}")
    public OrganizationResponse getById(
            @Parameter(description = "Id da organização") @PathVariable UUID id,
            Authentication authentication) {
        return service.findById(id, CurrentUser.isAdmin(authentication));
    }

    @Operation(
            summary = "Desativar organização",
            description = "Exclusão lógica: marca a organização como INACTIVE. Ela deixa de aparecer nas listagens e só o ADMIN pode reativar."
    )
    @DeleteMapping("/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void deactivate(
            @Parameter(description = "Id da organização") @PathVariable UUID id) {
        service.deactivate(id);
    }

    @Operation(
            summary = "Reativar organização",
            description = "Reverte a desativação lógica, voltando a organização para ACTIVE. Exclusivo do ADMIN."
    )
    @PostMapping("/{id}/reactivate")
    @PreAuthorize(SecurityExpressions.ADMIN)
    public void reactivate(
            @Parameter(description = "Id da organização") @PathVariable UUID id) {
        service.reactivate(id);
    }

    @Operation(
            summary = "Listar clubes/universidades de uma organização",
            description = "Lista as organizações filhas (CLUB/UNIVERSITY) associadas à organização informada, "
                    + "ordenadas por razão social. Acesso público."
    )
    @GetMapping("/{id}/clubs")
    public List<OrganizationResponse> listClubs(
            @Parameter(description = "Id da organização (federação/liga/associação)") @PathVariable UUID id) {
        return service.findClubs(id);
    }

    @Operation(
            summary = "Associar clube/universidade a uma organização",
            description = "Associa uma organização filha (CLUB/UNIVERSITY) à organização pai "
                    + "(FEDERATION/LEAGUE/ASSOCIATION). Requer ADMIN ou ORGANIZER. "
                    + "Retorna 409 se a organização filha já estiver associada."
    )
    @PostMapping("/{id}/clubs")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public OrganizationResponse associateClub(
            @Parameter(description = "Id da organização pai") @PathVariable UUID id,
            @Valid @RequestBody AssociateClubRequest request) {
        return service.associateClub(id, request.organizationId());
    }

    @Operation(
            summary = "Remover associação de clube/universidade",
            description = "Remove a associação de uma organização filha à organização pai "
                    + "(parent_id volta a null). Requer ADMIN ou ORGANIZER."
    )
    @DeleteMapping("/{id}/clubs/{clubId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void removeClub(
            @Parameter(description = "Id da organização pai") @PathVariable UUID id,
            @Parameter(description = "Id da organização filha (clube/universidade)") @PathVariable UUID clubId) {
        service.removeClubAssociation(id, clubId);
    }

}
