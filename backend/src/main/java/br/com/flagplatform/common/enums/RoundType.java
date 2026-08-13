package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum RoundType implements PersistableEnum {

    REGULAR("REGULAR", "Regular"),
    PLAYOFFS("PLAYOFFS", "Playoffs");

    private final String code;
    private final String description;

    RoundType(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
