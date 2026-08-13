package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.RoundType;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class RoundTypeConverter
        extends PersistableEnumConverter<RoundType> {

    public RoundTypeConverter() {
        super(RoundType.class);
    }

}
