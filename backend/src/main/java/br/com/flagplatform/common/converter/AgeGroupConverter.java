package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.AgeGroup;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class AgeGroupConverter
        extends PersistableEnumConverter<AgeGroup> {

    public AgeGroupConverter() {
        super(AgeGroup.class);
    }

}
