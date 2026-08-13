package br.com.flagplatform.round.mapper;

import br.com.flagplatform.round.dto.request.CreateRoundRequest;
import br.com.flagplatform.round.dto.request.UpdateRoundRequest;
import br.com.flagplatform.round.dto.response.RoundResponse;
import br.com.flagplatform.round.entity.RoundEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface RoundMapper {

    RoundEntity toEntity(CreateRoundRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    RoundEntity updateEntity(
            @MappingTarget RoundEntity entity,
            UpdateRoundRequest request);

    RoundResponse toResponse(RoundEntity entity);

    List<RoundResponse> toResponseList(List<RoundEntity> entities);

}
