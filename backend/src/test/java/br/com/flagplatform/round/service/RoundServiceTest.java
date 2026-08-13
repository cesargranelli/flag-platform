package br.com.flagplatform.round.service;

import br.com.flagplatform.category.CategoryLookup;
import br.com.flagplatform.category.exception.CategoryNotFoundException;
import br.com.flagplatform.common.enums.RoundType;
import br.com.flagplatform.round.dto.request.CreateRoundRequest;
import br.com.flagplatform.round.dto.request.UpdateRoundRequest;
import br.com.flagplatform.round.dto.response.RoundResponse;
import br.com.flagplatform.round.entity.RoundEntity;
import br.com.flagplatform.round.exception.DuplicateRoundNumberException;
import br.com.flagplatform.round.exception.RoundNotFoundException;
import br.com.flagplatform.round.mapper.RoundMapper;
import br.com.flagplatform.round.repository.RoundRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RoundServiceTest {

    @Mock
    private RoundMapper mapper;

    @Mock
    private RoundRepository repository;

    @Mock
    private CategoryLookup categoryLookup;

    @InjectMocks
    private RoundService service;

    @Test
    void create_savesRoundAfterValidatingCategory() {
        UUID categoryId = UUID.randomUUID();
        CreateRoundRequest request = createRequest(categoryId, 1);
        RoundEntity entity = entity(categoryId, 1, "Primeira Rodada");
        RoundResponse expected = response(entity);

        when(repository.existsByCategoryIdAndNumber(categoryId, request.number()))
                .thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        RoundResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        verify(categoryLookup).assertExists(categoryId);
        verify(repository).save(entity);
    }

    @Test
    void create_throwsWhenNumberAlreadyExistsForCategory() {
        UUID categoryId = UUID.randomUUID();
        CreateRoundRequest request = createRequest(categoryId, 1);

        when(repository.existsByCategoryIdAndNumber(categoryId, request.number()))
                .thenReturn(true);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(DuplicateRoundNumberException.class);

        verify(categoryLookup).assertExists(categoryId);
        verify(repository, never()).save(any());
    }

    @Test
    void create_throwsWhenCategoryDoesNotExist() {
        UUID categoryId = UUID.randomUUID();
        CreateRoundRequest request = createRequest(categoryId, 1);

        doThrow(new CategoryNotFoundException(categoryId))
                .when(categoryLookup).assertExists(categoryId);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(CategoryNotFoundException.class);

        verify(repository, never()).existsByCategoryIdAndNumber(any(), any());
        verify(repository, never()).save(any());
    }

    @Test
    void findByCategoryId_returnsRoundsOrderedByNumber() {
        UUID categoryId = UUID.randomUUID();
        List<RoundEntity> entities = List.of(
                entity(categoryId, 2, "Segunda Rodada"),
                entity(categoryId, 1, "Primeira Rodada"));
        List<RoundResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAllByCategoryIdOrderByNumberAsc(categoryId)).thenReturn(entities);
        when(mapper.toResponseList(entities)).thenReturn(expected);

        List<RoundResponse> response = service.findByCategoryId(categoryId);

        assertThat(response).hasSize(2).isSameAs(expected);
    }

    @Test
    void update_updatesExistingRound() {
        UUID id = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UpdateRoundRequest request = updateRequest(categoryId, 2);
        RoundEntity entity = entity(categoryId, 1, "Primeira Rodada");
        RoundResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCategoryIdAndNumberAndIdNot(
                categoryId, request.number(), id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        RoundResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(categoryLookup).assertExists(categoryId);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenRoundNotFound() {
        UUID id = UUID.randomUUID();
        UpdateRoundRequest request = updateRequest(UUID.randomUUID(), 1);

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(RoundNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenNumberUsedByAnotherRound() {
        UUID id = UUID.randomUUID();
        UUID categoryId = UUID.randomUUID();
        UpdateRoundRequest request = updateRequest(categoryId, 2);
        RoundEntity entity = entity(categoryId, 1, "Primeira Rodada");

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCategoryIdAndNumberAndIdNot(
                categoryId, request.number(), id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateRoundNumberException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateRoundRequest.class));
    }

    private CreateRoundRequest createRequest(UUID categoryId, Integer number) {
        return new CreateRoundRequest(categoryId, number, "Primeira Rodada", RoundType.REGULAR);
    }

    private UpdateRoundRequest updateRequest(UUID categoryId, Integer number) {
        return new UpdateRoundRequest(categoryId, number, "Primeira Rodada", RoundType.REGULAR);
    }

    private RoundEntity entity(UUID categoryId, Integer number, String name) {
        RoundEntity entity = new RoundEntity();
        entity.setId(UUID.randomUUID());
        entity.setCategoryId(categoryId);
        entity.setNumber(number);
        entity.setName(name);
        entity.setType(RoundType.REGULAR);
        return entity;
    }

    private RoundResponse response(RoundEntity entity) {
        return new RoundResponse(
                entity.getId(),
                entity.getCategoryId(),
                entity.getNumber(),
                entity.getName(),
                entity.getType(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
