package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.OrganizationType;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class OrganizationTypeConverter
        extends PersistableEnumConverter<OrganizationType> {

    public OrganizationTypeConverter() {
        super(OrganizationType.class);
    }

}
