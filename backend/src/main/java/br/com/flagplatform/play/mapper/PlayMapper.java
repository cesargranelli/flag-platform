package br.com.flagplatform.play.mapper;

import br.com.flagplatform.play.dto.request.CreatePlayRequest;
import br.com.flagplatform.play.dto.response.PlayResponse;
import br.com.flagplatform.play.entity.PlayEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

@Mapper(componentModel = "spring")
public interface PlayMapper {

    PlayEntity toEntity(CreatePlayRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    PlayEntity updateEntity(@MappingTarget PlayEntity entity, CreatePlayRequest request);

    @Mapping(target = "teamName", ignore = true)
    PlayResponse toResponse(PlayEntity entity);

}
