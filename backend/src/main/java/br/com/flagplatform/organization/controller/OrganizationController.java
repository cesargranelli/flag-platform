package br.com.flagplatform.organization.controller;

import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.request.UpdateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.dto.response.OrganizationResponse;
import br.com.flagplatform.common.security.SecurityExpressions;
import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.request.UpdateOrganizationRequest;
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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
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
            description = "Lista as organizações esportivas cadastradas, com paginação (page/size) e total no header X-Total-Count. Acesso público."
    )
    @GetMapping
    public List<OrganizationResponse> list(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            HttpServletResponse response) {
        var result = service.findAll(page, size);
        response.setHeader("X-Total-Count", String.valueOf(result.total()));
        return result.items();
    }

    @Operation(
            summary = "Buscar organização por id",
            description = "Retorna o detalhe de uma organização esportiva. Acesso público."
    )
    @GetMapping("/{id}")
    public OrganizationResponse getById(
            @Parameter(description = "Id da organização") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar organização",
            description = "Atualiza uma organização existente. Requer autenticação."
    )
    @PutMapping("/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public OrganizationResponse update(
            @Parameter(description = "Id da organização") @PathVariable UUID id,
            @Valid @RequestBody UpdateOrganizationRequest request) {
        return service.update(id, request);
    }

}
