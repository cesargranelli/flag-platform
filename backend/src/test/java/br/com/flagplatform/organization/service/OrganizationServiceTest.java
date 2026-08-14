package br.com.flagplatform.organization.service;

import br.com.flagplatform.common.enums.OrganizationStatus;
import br.com.flagplatform.common.enums.OrganizationType;
import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.request.UpdateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.dto.response.OrganizationResponse;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import br.com.flagplatform.organization.exception.DuplicateTradeNameException;
import br.com.flagplatform.organization.exception.OrganizationNotFoundException;
import br.com.flagplatform.organization.mapper.OrganizationMapper;
import br.com.flagplatform.organization.repository.OrganizationRepository;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OrganizationServiceTest {

    @Mock
    private OrganizationMapper mapper;

    @Mock
    private OrganizationRepository repository;

    @InjectMocks
    private OrganizationService service;

    @Test
    void create_savesOrganizationAsActive() {
        CreateOrganizationRequest request = createRequest();
        OrganizationEntity entity = entity("APFA", "APFA - Paulista de Flag Football");
        OrganizationCreatedResponse expected = new OrganizationCreatedResponse(
                entity.getId(), entity.getTradeName(), "Organization created successfully");

        when(repository.existsByTradeNameIgnoreCase(request.tradeName())).thenReturn(false);
        when(mapper.toEntity(request)).thenReturn(entity);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toResponse(entity)).thenReturn(expected);

        OrganizationCreatedResponse response = service.create(request);

        assertThat(response).isSameAs(expected);
        assertThat(entity.getStatus()).isEqualTo(OrganizationStatus.ACTIVE);
        verify(repository).save(entity);
    }

    @Test
    void create_throwsWhenTradeNameAlreadyExists() {
        CreateOrganizationRequest request = createRequest();

        when(repository.existsByTradeNameIgnoreCase(request.tradeName())).thenReturn(true);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(DuplicateTradeNameException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void findAll_returnsMappedOrganizations() {
        List<OrganizationEntity> entities = List.of(entity("A", "Org A"), entity("B", "Org B"));
        List<OrganizationResponse> expected = entities.stream()
                .map(this::detailResponse)
                .toList();

        when(repository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(entities));
        when(mapper.toDetailResponseList(entities)).thenReturn(expected);

        var response = service.findAll(0, 10);

        assertThat(response.items()).hasSize(2).isSameAs(expected);
        assertThat(response.total()).isEqualTo(2);
    }

    @Test
    void findById_returnsMappedOrganization() {
        UUID id = UUID.randomUUID();
        OrganizationEntity entity = entity("APFA", "APFA");
        OrganizationResponse expected = detailResponse(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(mapper.toDetailResponse(entity)).thenReturn(expected);

        OrganizationResponse response = service.findById(id);

        assertThat(response).isSameAs(expected);
    }

    @Test
    void findById_throwsWhenOrganizationNotFound() {
        UUID id = UUID.randomUUID();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.findById(id))
                .isInstanceOf(OrganizationNotFoundException.class);
    }

    @Test
    void update_updatesExistingOrganization() {
        UUID id = UUID.randomUUID();
        UpdateOrganizationRequest request = updateRequest();
        OrganizationEntity entity = entity("APFA", "APFA");
        OrganizationResponse expected = detailResponse(entity);

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByTradeNameIgnoreCaseAndIdNot(request.tradeName(), id)).thenReturn(false);
        when(repository.save(entity)).thenReturn(entity);
        when(mapper.toDetailResponse(entity)).thenReturn(expected);

        OrganizationResponse response = service.update(id, request);

        assertThat(response).isSameAs(expected);
        verify(mapper).updateEntity(entity, request);
        verify(repository).save(entity);
    }

    @Test
    void update_throwsWhenOrganizationNotFound() {
        UUID id = UUID.randomUUID();
        UpdateOrganizationRequest request = updateRequest();

        when(repository.findById(id)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(OrganizationNotFoundException.class);

        verify(repository, never()).save(any());
    }

    @Test
    void update_throwsWhenTradeNameUsedByAnotherOrganization() {
        UUID id = UUID.randomUUID();
        UpdateOrganizationRequest request = updateRequest();
        OrganizationEntity entity = entity("APFA", "APFA");

        when(repository.findById(id)).thenReturn(Optional.of(entity));
        when(repository.existsByTradeNameIgnoreCaseAndIdNot(request.tradeName(), id)).thenReturn(true);

        assertThatThrownBy(() -> service.update(id, request))
                .isInstanceOf(DuplicateTradeNameException.class);

        verify(repository, never()).save(any());
        verify(mapper, never()).updateEntity(eq(entity), any(UpdateOrganizationRequest.class));
    }

    private CreateOrganizationRequest createRequest() {
        return new CreateOrganizationRequest(
                "Associação Paulista de Futebol Americano",
                "APFA",
                "APFA",
                OrganizationType.ASSOCIATION,
                "contato@apfa.com.br",
                "11999999999",
                "https://apfa.com.br",
                "apfa.flag",
                "BR",
                "São Paulo",
                "São Paulo",
                "https://apfa.com.br/logo.png",
                "#000000",
                "#FFFFFF",
                "America/Sao_Paulo",
                "pt-BR"
        );
    }

    private UpdateOrganizationRequest updateRequest() {
        return new UpdateOrganizationRequest(
                "Associação Paulista de Futebol Americano",
                "APFA 2026",
                "APFA",
                OrganizationType.ASSOCIATION,
                "contato@apfa.com.br",
                "11999999999",
                "https://apfa.com.br",
                "apfa.flag",
                "BR",
                "São Paulo",
                "São Paulo",
                "https://apfa.com.br/logo.png",
                "#000000",
                "#FFFFFF",
                "America/Sao_Paulo",
                "pt-BR"
        );
    }

    private OrganizationEntity entity(String tradeName, String legalName) {
        OrganizationEntity entity = new OrganizationEntity();
        entity.setId(UUID.randomUUID());
        entity.setLegalName(legalName);
        entity.setTradeName(tradeName);
        entity.setOrganizationType(OrganizationType.ASSOCIATION);
        entity.setCountry("BR");
        entity.setTimezone("America/Sao_Paulo");
        entity.setLocale("pt-BR");
        entity.setStatus(OrganizationStatus.ACTIVE);
        return entity;
    }

    private OrganizationResponse detailResponse(OrganizationEntity entity) {
        return new OrganizationResponse(
                entity.getId(),
                entity.getLegalName(),
                entity.getTradeName(),
                entity.getAbbreviation(),
                entity.getOrganizationType(),
                entity.getEmail(),
                entity.getPhone(),
                entity.getWebsite(),
                entity.getInstagram(),
                entity.getCountry(),
                entity.getState(),
                entity.getCity(),
                entity.getLogoUrl(),
                entity.getPrimaryColor(),
                entity.getSecondaryColor(),
                entity.getTimezone(),
                entity.getLocale(),
                entity.getStatus(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

}
