package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum AthletePosition implements PersistableEnum {

    QB("QB", "Quarterback"),
    RB("RB", "Running Back"),
    WR("WR", "Wide Receiver"),
    TE("TE", "Tight End"),
    C("C", "Center"),
    DL("DL", "Defensive Lineman"),
    LB("LB", "Linebacker"),
    DB("DB", "Defensive Back"),
    K("K", "Kicker"),
    P("P", "Punter");

    private final String code;
    private final String description;

    AthletePosition(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
