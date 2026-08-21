package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.Modality;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class ModalityConverter
        extends PersistableEnumConverter<Modality> {

    public ModalityConverter() {
        super(Modality.class);
    }

}
