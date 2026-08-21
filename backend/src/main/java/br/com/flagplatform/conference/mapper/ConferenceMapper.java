package br.com.flagplatform.conference.mapper;

import br.com.flagplatform.conference.dto.request.CreateConferenceRequest;
import br.com.flagplatform.conference.dto.request.UpdateConferenceRequest;
import br.com.flagplatform.conference.dto.response.ConferenceResponse;
import br.com.flagplatform.conference.entity.ConferenceEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;
import java.util.UUID;

@Mapper(componentModel = "spring")
public interface ConferenceMapper {

    ConferenceEntity toEntity(UUID competitionId, CreateConferenceRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    ConferenceEntity updateEntity(
            @MappingTarget ConferenceEntity entity,
            UpdateConferenceRequest request);

    ConferenceResponse toResponse(ConferenceEntity entity);

    List<ConferenceResponse> toResponseList(List<ConferenceEntity> entities);

}
