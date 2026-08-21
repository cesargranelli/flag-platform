package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum Modality implements PersistableEnum {

    FLAG_5X5("FLAG_5X5", "Flag 5x5"),
    FLAG_8X8("FLAG_8X8", "Flag 8x8"),
    FLAG_9X9("FLAG_9X9", "Flag 9x9"),
    FULL_PADS_11X11("FULL_PADS_11X11", "Full Pads 11x11");

    private final String code;
    private final String description;

    Modality(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
