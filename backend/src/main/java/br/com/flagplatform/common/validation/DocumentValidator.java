package br.com.flagplatform.common.validation;

import br.com.flagplatform.common.enums.DocumentType;

/**
 * Valida documentos brasileiros (CPF e CNPJ) pelos digitos verificadores.
 */
public final class DocumentValidator {

    private DocumentValidator() {
    }

    /**
     * Valida um documento conforme o tipo informado. Retorna {@code true} se
     * o documento for vazio (tratado em outro ponto como obrigatoriedade) ou
     * se os digitos verificadores forem validos.
     */
    public static boolean isValid(String document, DocumentType type) {
        if (document == null || document.isBlank()) {
            return false;
        }
        String digits = document.replaceAll("\\D", "");
        return switch (type) {
            case CPF -> isValidCpf(digits);
            case CNPJ -> isValidCnpj(digits);
        };
    }

    private static boolean isValidCpf(String cpf) {
        if (cpf == null || cpf.length() != 11) {
            return false;
        }
        if (cpf.chars().distinct().count() == 1) {
            return false;
        }
        int[] digits = cpf.chars().map(c -> c - '0').toArray();
        int d1 = calculate(digits, 10, 9);
        int d2 = calculate(digits, 11, 10);
        return d1 == digits[9] && d2 == digits[10];
    }

    private static boolean isValidCnpj(String cnpj) {
        if (cnpj == null || cnpj.length() != 14) {
            return false;
        }
        if (cnpj.chars().distinct().count() == 1) {
            return false;
        }
        int[] digits = cnpj.chars().map(c -> c - '0').toArray();
        int[] w1 = {5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int[] w2 = {6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int d1 = calcWeighted(digits, w1, 12);
        int d2 = calcWeighted(digits, w2, 13);
        return d1 == digits[12] && d2 == digits[13];
    }

    private static int calculate(int[] digits, int start, int limit) {
        int sum = 0;
        for (int i = 0; i < limit; i++) {
            sum += digits[i] * (start - i);
        }
        int rest = (sum * 10) % 11;
        return rest == 10 ? 0 : rest;
    }

    private static int calcWeighted(int[] digits, int[] weights, int length) {
        int sum = 0;
        for (int i = 0; i < length; i++) {
            sum += digits[i] * weights[i];
        }
        int rest = sum % 11;
        return rest < 2 ? 0 : 11 - rest;
    }

}
