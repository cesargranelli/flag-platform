package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum GameStatus implements PersistableEnum {

    SCHEDULED("SCHEDULED", "Scheduled"),
    IN_PROGRESS("IN_PROGRESS", "In progress"),
    FINISHED("FINISHED", "Finished"),
    CANCELLED("CANCELLED", "Cancelled");

    private final String code;
    private final String description;

    GameStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
