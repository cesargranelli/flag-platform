package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum AthleteStatus implements PersistableEnum {

    ACTIVE("ACTIVE", "Ativo"),
    INACTIVE("INACTIVE", "Inativo");

    private final String code;
    private final String description;

    AthleteStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}