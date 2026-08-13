package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.CheckInStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class CheckInStatusConverter
        extends PersistableEnumConverter<CheckInStatus> {

    public CheckInStatusConverter() {
        super(CheckInStatus.class);
    }

}
