package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum ContactType implements PersistableEnum {

    FLAG("FLAG", "Flag"),
    FULL_PAD("FULL_PAD", "Equipado"),
    BEACH("BEACH", "Areia");

    private final String code;
    private final String description;

    ContactType(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
