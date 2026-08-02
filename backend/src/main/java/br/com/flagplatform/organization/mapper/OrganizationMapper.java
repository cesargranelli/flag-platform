package br.com.flagplatform.organization.mapper;

import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface OrganizationMapper {

    OrganizationEntity toEntity(CreateOrganizationRequest request);

    OrganizationCreatedResponse toResponse(OrganizationEntity entity);

}
