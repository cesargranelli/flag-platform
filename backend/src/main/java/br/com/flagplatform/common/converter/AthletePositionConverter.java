package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.AthletePosition;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class AthletePositionConverter
        extends PersistableEnumConverter<AthletePosition> {

    public AthletePositionConverter() {
        super(AthletePosition.class);
    }

}
