package br.com.flagplatform.user.mapper;

import br.com.flagplatform.user.dto.request.RegisterRequest;
import br.com.flagplatform.user.dto.response.UserResponse;
import br.com.flagplatform.user.entity.UserEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(componentModel = "spring")
public interface UserMapper {

    @Mapping(target = "passwordHash", source = "password")
    UserEntity toEntity(RegisterRequest request);

    UserResponse toResponse(UserEntity entity);

    List<UserResponse> toResponseList(List<UserEntity> entities);

}
