package br.com.flagplatform.division.mapper;

import br.com.flagplatform.division.dto.request.CreateDivisionRequest;
import br.com.flagplatform.division.dto.request.UpdateDivisionRequest;
import br.com.flagplatform.division.dto.response.DivisionResponse;
import br.com.flagplatform.division.entity.DivisionEntity;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

import java.util.List;
import java.util.UUID;

@Mapper(componentModel = "spring")
public interface DivisionMapper {

    DivisionEntity toEntity(UUID competitionId, CreateDivisionRequest request);

    DivisionEntity updateEntity(
            @MappingTarget DivisionEntity entity,
            UpdateDivisionRequest request);

    DivisionResponse toResponse(DivisionEntity entity);

    List<DivisionResponse> toResponseList(List<DivisionEntity> entities);

}
