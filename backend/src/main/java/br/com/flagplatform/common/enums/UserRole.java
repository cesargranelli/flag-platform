package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum UserRole implements PersistableEnum {

    ADMIN("ADMIN", "Administrador"),
    ORGANIZER("ORGANIZER", "Organizador"),
    MESA("MESA", "Mesa");

    private final String code;
    private final String description;

    UserRole(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
