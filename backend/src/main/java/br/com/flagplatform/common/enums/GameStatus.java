package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum GameStatus implements PersistableEnum {

    SCHEDULED("SCHEDULED", "Scheduled"),
    OPEN("OPEN", "Open"),
    IN_PROGRESS("IN_PROGRESS", "In progress"),
    CONFERENCE("CONFERENCE", "Conference"),
    FINISHED("FINISHED", "Finished"),
    CANCELLED("CANCELLED", "Cancelled");

    private final String code;
    private final String description;

    GameStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
