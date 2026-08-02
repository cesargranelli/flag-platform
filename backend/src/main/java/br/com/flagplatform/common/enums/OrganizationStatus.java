package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum OrganizationStatus implements PersistableEnum {

    ACTIVE("ACTIVE", "Active"),
    INACTIVE("INACTIVE", "Inactive");

    private final String code;
    private final String description;

    OrganizationStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
