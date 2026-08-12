package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.CompetitionStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class CompetitionStatusConverter
        extends PersistableEnumConverter<CompetitionStatus> {

    public CompetitionStatusConverter() {
        super(CompetitionStatus.class);
    }

}
