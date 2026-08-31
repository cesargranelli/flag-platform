package br.com.flagplatform.team.mapper;

import br.com.flagplatform.organization.OrganizationLookup;
import br.com.flagplatform.team.dto.request.CreateTeamRequest;
import br.com.flagplatform.team.dto.request.UpdateTeamRequest;
import br.com.flagplatform.team.dto.response.TeamResponse;
import br.com.flagplatform.team.entity.TeamEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface TeamMapper {

    TeamEntity toEntity(CreateTeamRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    TeamEntity updateEntity(
            @MappingTarget TeamEntity entity,
            UpdateTeamRequest request);

    @Mapping(target = "organizationName", ignore = true)
    TeamResponse toResponse(TeamEntity entity);

    List<TeamResponse> toResponseList(List<TeamEntity> entities);

}