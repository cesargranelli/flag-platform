package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum RosterStatus implements PersistableEnum {

    ACTIVE("ACTIVE", "Ativo"),
    INACTIVE("INACTIVE", "Inativo");

    private final String code;
    private final String description;

    RosterStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
