package br.com.flagplatform.athlete.service;

import br.com.flagplatform.athlete.dto.request.CreateAthleteRequest;
import br.com.flagplatform.athlete.dto.request.UpdateAthleteRequest;
import br.com.flagplatform.athlete.dto.response.AthleteResponse;
import br.com.flagplatform.athlete.entity.AthleteEntity;
import br.com.flagplatform.athlete.exception.AthleteNotFoundException;
import br.com.flagplatform.athlete.mapper.AthleteMapper;
import br.com.flagplatform.athlete.repository.AthleteRepository;
import br.com.flagplatform.common.enums.AthletePosition;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AthleteServiceTest {

    @Mock
    private AthleteMapper mapper;

    @Mock
    private AthleteRepository repository;

    @InjectMocks
    private AthleteService service;

    @Test
    void create_savesAthleteAndReturnsResponse() {
        CreateAthleteRequest request = createRequest(
                "João Silva", "João", AthletePosition.QB, 7, null);
        AthleteEntity entity = entity("João Silva", AthletePosition.QB, 7);
        AthleteResponse expected = response(entity);

        when(repository.existsByCpf("12345678909")).thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        AthleteResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        verify(repository).save(entity);
    }

    @Test
    void findAll_returnsAthletesOrderedByName() {
        List<AthleteEntity> entities = List.of(
                entity("Bia", null, null),
                entity("Ana", null, null));
        List<AthleteResponse> expected = entities.stream()
                .map(this::response)
                .toList();

        when(repository.findAll(any(Pageable.class)))
                .thenReturn(new PageImpl<>(entities));
        when(mapper.toResponseList(entities)).thenReturn(expected);

        var response = service.findAll(0, 10);

        assertThat(response.items()).hasSize(2).isSameAs(expected);
        assertThat(response.total()).isEqualTo(2);
    }

    @Test
    void findById_returnsAthleteWhenFound() {
        UUID id = UUID.randomUUID();
        AthleteEntity entity = entity("João Silva", AthletePosition.WR, 10);
        AthleteResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(mapper.toResponse(entity)).thenReturn(expected);

        AthleteResponse response = service.findById(id);

        assertThat(response).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenAthleteNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(AthleteNotFoundException.class);
    }

    @Test
    void update_updatesExistingAthlete() {
        UUID id = UUID.randomUUID();
        UpdateAthleteRequest request = updateRequest(
                "João Silva", "Joãozinho", AthletePosition.RB, 21, "https://foto.com/joao.png");
        AthleteEntity entity = entity("João Silva", AthletePosition.QB, 7);
        AthleteResponse expected = response(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByCpfAndIdNot("12345678909", id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        AthleteResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenAthleteNotFound() {
        UUID id = UUID.randomUUID();
        UpdateAthleteRequest request = updateRequest("João Silva", null, null, null, null);

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(AthleteNotFoundException.class);

        verify(repository, never()).save(any());
    }

    private CreateAthleteRequest createRequest(String name, String nickname,
                                               AthletePosition position, Integer number,
                                               String photoUrl) {
        return new CreateAthleteRequest(name, "12345678909", nickname, position, number, photoUrl);
    }

    private UpdateAthleteRequest updateRequest(String name, String nickname,
                                               AthletePosition position, Integer number,
                                               String photoUrl) {
        return new UpdateAthleteRequest(name, "12345678909", nickname, position, number, photoUrl);
    }

    private AthleteEntity entity(String name, AthletePosition position, Integer number) {
        AthleteEntity entity = new AthleteEntity();
        entity.setId(UUID.randomUUID());
        entity.setName(name);
        entity.setCpf("12345678909");
        entity.setPosition(position);
        entity.setNumber(number);
        return entity;
    }

    private AthleteResponse response(AthleteEntity entity) {
        return new AthleteResponse(
                entity.getId(),
                entity.getName(),
                entity.getCpf(),
                entity.getNickname(),
                entity.getPosition(),
                entity.getNumber(),
                entity.getPhotoUrl(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
