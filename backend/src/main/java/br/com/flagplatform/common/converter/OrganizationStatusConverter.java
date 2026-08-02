package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.OrganizationStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class OrganizationStatusConverter
        extends PersistableEnumConverter<OrganizationStatus> {

    public OrganizationStatusConverter() {
        super(OrganizationStatus.class);
    }

}
