package br.com.flagplatform.venue.mapper;

import br.com.flagplatform.venue.dto.request.CreateVenueRequest;
import br.com.flagplatform.venue.dto.request.UpdateVenueRequest;
import br.com.flagplatform.venue.dto.response.VenueResponse;
import br.com.flagplatform.venue.entity.VenueEntity;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface VenueMapper {

    VenueEntity toEntity(CreateVenueRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    VenueEntity updateEntity(
            @MappingTarget VenueEntity entity,
            UpdateVenueRequest request);

    VenueResponse toResponse(VenueEntity entity);

    List<VenueResponse> toResponseList(List<VenueEntity> entities);

}
