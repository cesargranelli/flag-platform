package br.com.flagplatform.organization.mapper;

import br.com.flagplatform.organization.dto.request.CreateOrganizationRequest;
import br.com.flagplatform.organization.dto.response.OrganizationCreatedResponse;
import br.com.flagplatform.organization.dto.response.OrganizationResponse;
import br.com.flagplatform.organization.entity.OrganizationEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface OrganizationMapper {

    OrganizationEntity toEntity(CreateOrganizationRequest request);

    @Mapping(target = "message", constant = "Organization created successfully")
    OrganizationCreatedResponse toResponse(OrganizationEntity entity);

    OrganizationResponse toDetailResponse(OrganizationEntity entity);

    List<OrganizationResponse> toDetailResponseList(List<OrganizationEntity> entities);

}
