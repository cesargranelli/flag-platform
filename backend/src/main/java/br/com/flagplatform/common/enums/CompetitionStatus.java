package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum CompetitionStatus implements PersistableEnum {

    DRAFT("DRAFT", "Draft"),
    PUBLISHED("PUBLISHED", "Published"),
    FINISHED("FINISHED", "Finished"),
    DISABLED("DISABLED", "Desativado");

    private final String code;
    private final String description;

    CompetitionStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
