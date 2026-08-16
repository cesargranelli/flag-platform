package br.com.flagplatform.category.controller;

import br.com.flagplatform.category.dto.request.CreateCategoryRequest;
import br.com.flagplatform.category.dto.request.UpdateCategoryRequest;
import br.com.flagplatform.category.dto.response.CategoryResponse;
import br.com.flagplatform.category.service.CategoryService;
import br.com.flagplatform.common.security.SecurityExpressions;
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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Categories", description = "Endpoints para criar e gerenciar categorias de campeonatos")
@RestController
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService service;

    @Operation(
            summary = "Criar categoria",
            description = "Cria uma nova categoria de campeonato. Requer autenticação."
    )
    @PostMapping("/api/v1/categories")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CategoryResponse create(@Valid @RequestBody CreateCategoryRequest request) {
        return service.create(request);
    }

    @Operation(
            summary = "Listar categorias por campeonato",
            description = "Lista as categorias de um campeonato, ordenadas por nome. Acesso público."
    )
    @GetMapping("/api/v1/competitions/{competitionId}/categories")
    public List<CategoryResponse> findByCompetitionId(
            @Parameter(description = "Id do campeonato") @PathVariable UUID competitionId) {
        return service.findByCompetitionId(competitionId);
    }

    @Operation(
            summary = "Obter categoria",
            description = "Retorna o detalhe de uma categoria. Acesso público."
    )
    @GetMapping("/api/v1/categories/{id}")
    public CategoryResponse findById(
            @Parameter(description = "Id da categoria") @PathVariable UUID id) {
        return service.findById(id);
    }

    @Operation(
            summary = "Atualizar categoria",
            description = "Atualiza uma categoria existente. Requer autenticação."
    )
    @PutMapping("/api/v1/categories/{id}")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public CategoryResponse update(
            @Parameter(description = "Id da categoria") @PathVariable UUID id,
            @Valid @RequestBody UpdateCategoryRequest request) {
        return service.update(id, request);
    }

    @Operation(
            summary = "Excluir categoria",
            description = "Exclui uma categoria existente. Requer autenticação. " +
                    "Pode falhar caso existam dependências vinculadas à categoria."
    )
    @DeleteMapping("/api/v1/categories/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public void delete(
            @Parameter(description = "Id da categoria") @PathVariable UUID id) {
        service.delete(id);
    }

}
