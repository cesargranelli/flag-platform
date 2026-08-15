package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.UserStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class UserStatusConverter
        extends PersistableEnumConverter<UserStatus> {

    public UserStatusConverter() {
        super(UserStatus.class);
    }

}
