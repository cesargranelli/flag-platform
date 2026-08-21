package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum DocumentType implements PersistableEnum {

    CNPJ("CNPJ", "CNPJ"),
    CPF("CPF", "CPF");

    private final String code;
    private final String description;

    DocumentType(String code, String description) {
        this.code = code;
        this.description = description;
    }

}
