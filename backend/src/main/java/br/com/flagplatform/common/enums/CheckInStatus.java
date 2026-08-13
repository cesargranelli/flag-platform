package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum CheckInStatus implements PersistableEnum {

    PRESENT("PRESENT", "Presente"),
    NO_SHOW("NO_SHOW", "Não compareceu"),
    NOT_REGISTERED("NOT_REGISTERED", "Não registrado no roster");

    private final String code;
    private final String description;

    CheckInStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
