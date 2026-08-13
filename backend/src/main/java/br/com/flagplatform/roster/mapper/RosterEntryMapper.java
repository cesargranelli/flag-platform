package br.com.flagplatform.roster.mapper;

import br.com.flagplatform.roster.dto.request.AddRosterEntryRequest;
import br.com.flagplatform.roster.entity.RosterEntryEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface RosterEntryMapper {

    RosterEntryEntity toEntity(AddRosterEntryRequest request);

}
