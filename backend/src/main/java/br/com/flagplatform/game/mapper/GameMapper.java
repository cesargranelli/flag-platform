package br.com.flagplatform.game.mapper;

import br.com.flagplatform.game.dto.request.CreateGameRequest;
import br.com.flagplatform.game.dto.request.UpdateGameRequest;
import br.com.flagplatform.game.dto.response.GameResponse;
import br.com.flagplatform.game.entity.GameEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface GameMapper {

    GameEntity toEntity(CreateGameRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    GameEntity updateEntity(
            @MappingTarget GameEntity entity,
            UpdateGameRequest request);

    GameResponse toResponse(GameEntity entity);

    List<GameResponse> toResponseList(List<GameEntity> entities);

}
