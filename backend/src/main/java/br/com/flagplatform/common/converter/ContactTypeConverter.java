package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.ContactType;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class ContactTypeConverter
        extends PersistableEnumConverter<ContactType> {

    public ContactTypeConverter() {
        super(ContactType.class);
    }

}
