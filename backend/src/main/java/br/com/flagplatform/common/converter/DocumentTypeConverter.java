package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.DocumentType;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class DocumentTypeConverter
        extends PersistableEnumConverter<DocumentType> {

    public DocumentTypeConverter() {
        super(DocumentType.class);
    }

}
