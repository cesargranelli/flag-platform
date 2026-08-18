package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum AgeGroup implements PersistableEnum {

    SUB11("SUB11", "Sub-11"),
    SUB13("SUB13", "Sub-13"),
    SUB14("SUB14", "Sub-14"),
    SUB15("SUB15", "Sub-15"),
    SUB17("SUB17", "Sub-17"),
    SUB20("SUB20", "Sub-20"),
    ADULT("ADULT", "Adulto"),
    MASTER("MASTER", "Master"),
    OPEN("OPEN", "Livre");

    private final String code;
    private final String description;

    AgeGroup(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
