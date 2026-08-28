package br.com.flagplatform.play.entity;

import lombok.Getter;

@Getter
public enum PlayType {

    RUN("RUN", "Run"),
    PASS("PASS", "Pass"),
    TOUCHDOWN("TOUCHDOWN", "Touchdown"),
    INTERCEPTION("INTERCEPTION", "Interception"),
    FIELD_GOAL("FIELD_GOAL", "Field Goal"),
    PUNT("PUNT", "Punt"),
    KICKOFF("KICKOFF", "Kickoff"),
    PENALTY("PENALTY", "Penalty"),
    FIRST_DOWN("FIRST_DOWN", "First Down");

    private final String code;
    private final String description;

    PlayType(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
