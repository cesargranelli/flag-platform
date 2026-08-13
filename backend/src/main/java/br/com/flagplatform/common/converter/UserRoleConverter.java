package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.UserRole;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class UserRoleConverter
        extends PersistableEnumConverter<UserRole> {

    public UserRoleConverter() {
        super(UserRole.class);
    }

}
