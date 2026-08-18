package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum Gender implements PersistableEnum {

    MALE("MALE", "Masculino"),
    FEMALE("FEMALE", "Feminino"),
    MIXED("MIXED", "Misto");

    private final String code;
    private final String description;

    Gender(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
