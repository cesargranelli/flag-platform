package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum GroupingType implements PersistableEnum {

    DIVISIONS("DIVISIONS", "Divisões"),
    GROUPS("GROUPS", "Grupos");

    private final String code;
    private final String description;

    GroupingType(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
