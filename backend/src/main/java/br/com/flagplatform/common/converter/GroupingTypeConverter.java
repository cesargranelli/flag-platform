package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.GroupingType;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class GroupingTypeConverter extends PersistableEnumConverter<GroupingType> {

    public GroupingTypeConverter() {
        super(GroupingType.class);
    }

}
