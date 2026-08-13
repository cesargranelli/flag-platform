package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.RosterStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class RosterStatusConverter
        extends PersistableEnumConverter<RosterStatus> {

    public RosterStatusConverter() {
        super(RosterStatus.class);
    }

}
