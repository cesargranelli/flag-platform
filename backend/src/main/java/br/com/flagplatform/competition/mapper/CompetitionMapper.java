package br.com.flagplatform.competition.mapper;

import br.com.flagplatform.competition.dto.request.CreateCompetitionRequest;
import br.com.flagplatform.competition.dto.request.UpdateCompetitionRequest;
import br.com.flagplatform.competition.dto.response.CompetitionResponse;
import br.com.flagplatform.competition.entity.CompetitionEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface CompetitionMapper {

    CompetitionEntity toEntity(CreateCompetitionRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    CompetitionEntity updateEntity(
            @MappingTarget CompetitionEntity entity,
            UpdateCompetitionRequest request);

    CompetitionResponse toResponse(CompetitionEntity entity);

    List<CompetitionResponse> toResponseList(List<CompetitionEntity> entities);

}
