package br.com.flagplatform.modality.mapper;

import br.com.flagplatform.modality.dto.response.ModalityResponse;
import br.com.flagplatform.modality.entity.ModalityEntity;
import org.mapstruct.Mapper;

import java.util.List;

@Mapper(componentModel = "spring")
public interface ModalityMapper {

    ModalityResponse toResponse(ModalityEntity entity);

    List<ModalityResponse> toResponseList(List<ModalityEntity> entities);

}
