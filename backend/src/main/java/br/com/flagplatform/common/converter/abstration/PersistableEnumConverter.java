package br.com.flagplatform.common.converter.abstration;

import br.com.flagplatform.common.enums.PersistableEnum;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public abstract class PersistableEnumConverter<E extends Enum<E> & PersistableEnum>
        implements AttributeConverter<E, String> {

    private final Class<E> enumClass;

    protected PersistableEnumConverter(Class<E> enumClass) {
        this.enumClass = enumClass;
    }

    @Override
    public String convertToDatabaseColumn(E attribute) {

        if (attribute == null) {
            return null;
        }

        return attribute.getCode();
    }

    @Override
    public E convertToEntityAttribute(String dbData) {

        if (dbData == null) {
            return null;
        }

        for (E constant : enumClass.getEnumConstants()) {

            if (constant.getCode().equals(dbData)) {
                return constant;
            }
        }

        throw new IllegalArgumentException(
                "Unknown enum value '%s' for %s"
                        .formatted(dbData, enumClass.getSimpleName()));
    }

}
