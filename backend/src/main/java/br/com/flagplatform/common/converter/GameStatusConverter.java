package br.com.flagplatform.common.converter;

import br.com.flagplatform.common.converter.abstration.PersistableEnumConverter;
import br.com.flagplatform.common.enums.GameStatus;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class GameStatusConverter
        extends PersistableEnumConverter<GameStatus> {

    public GameStatusConverter() {
        super(GameStatus.class);
    }

}
