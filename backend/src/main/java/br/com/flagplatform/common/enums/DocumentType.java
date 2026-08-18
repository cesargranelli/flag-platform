package br.com.flagplatform.common.enums;

import lombok.Getter;

@Getter
public enum DocumentType {

    CNPJ("CNPJ"),
    CPF("CPF");

    private final String code;

    DocumentType(String code) {
        this.code = code;
    }

}
