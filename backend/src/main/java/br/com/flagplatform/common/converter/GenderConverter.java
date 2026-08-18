package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.Gender;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class GenderConverter
        extends PersistableEnumConverter<Gender> {

    public GenderConverter() {
        super(Gender.class);
    }

}
