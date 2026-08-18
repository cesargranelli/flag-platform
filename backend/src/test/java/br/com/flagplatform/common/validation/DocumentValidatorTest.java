package br.com.flagplatform.common.validation;

import br.com.flagplatform.common.enums.DocumentType;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class DocumentValidatorTest {

    @Test
    void cpf_valid() {
        assertThat(DocumentValidator.isValid("123.456.789-09", DocumentType.CPF)).isTrue();
        assertThat(DocumentValidator.isValid("12345678909", DocumentType.CPF)).isTrue();
    }

    @Test
    void cpf_invalid() {
        assertThat(DocumentValidator.isValid("111.111.111-11", DocumentType.CPF)).isFalse();
        assertThat(DocumentValidator.isValid("12345678900", DocumentType.CPF)).isFalse();
        assertThat(DocumentValidator.isValid("123456", DocumentType.CPF)).isFalse();
    }

    @Test
    void cnpj_valid() {
        assertThat(DocumentValidator.isValid("11.222.333/0001-81", DocumentType.CNPJ)).isTrue();
        assertThat(DocumentValidator.isValid("11222333000181", DocumentType.CNPJ)).isTrue();
    }

    @Test
    void cnpj_invalid() {
        assertThat(DocumentValidator.isValid("11.111.111/1111-11", DocumentType.CNPJ)).isFalse();
        assertThat(DocumentValidator.isValid("11222333000100", DocumentType.CNPJ)).isFalse();
        assertThat(DocumentValidator.isValid("123", DocumentType.CNPJ)).isFalse();
    }

    @Test
    void emptyOrNull_returnsFalse() {
        assertThat(DocumentValidator.isValid(null, DocumentType.CPF)).isFalse();
        assertThat(DocumentValidator.isValid("", DocumentType.CNPJ)).isFalse();
        assertThat(DocumentValidator.isValid("   ", DocumentType.CPF)).isFalse();
    }
}
