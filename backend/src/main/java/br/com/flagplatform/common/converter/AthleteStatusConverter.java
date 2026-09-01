package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.AthleteStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class AthleteStatusConverter
        extends PersistableEnumConverter<AthleteStatus> {

    public AthleteStatusConverter() {
        super(AthleteStatus.class);
    }

}