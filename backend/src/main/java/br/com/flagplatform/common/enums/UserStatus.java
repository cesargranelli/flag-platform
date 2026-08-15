package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum UserStatus implements PersistableEnum {

    PENDING("PENDING", "Aguardando aprovação"),
    ACTIVE("ACTIVE", "Ativo"),
    REJECTED("REJECTED", "Rejeitado");

    private final String code;
    private final String description;

    UserStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
