package br.com.flagplatform.athlete.mapper;

import br.com.flagplatform.athlete.dto.request.CreateAthleteRequest;
import br.com.flagplatform.athlete.dto.request.UpdateAthleteRequest;
import br.com.flagplatform.athlete.dto.response.AthleteResponse;
import br.com.flagplatform.athlete.entity.AthleteEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface AthleteMapper {

    AthleteEntity toEntity(CreateAthleteRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    AthleteEntity updateEntity(
            @MappingTarget AthleteEntity entity,
            UpdateAthleteRequest request);

    AthleteResponse toResponse(AthleteEntity entity);

    List<AthleteResponse> toResponseList(List<AthleteEntity> entities);

}
